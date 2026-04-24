//
//  FirebaseNotificationService.swift
//  Resell
//
//  Created by Richie Sun on 12/3/24.
//

import Foundation
import FirebaseMessaging
import UserNotifications
import UIKit
import os

class FirebaseNotificationService: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {

    // MARK: - Singleton Instance

    static let shared = FirebaseNotificationService()

    // MARK: - Error Logger for Networking

    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.cornellappdev.Resell", category: #file)

    // MARK: - Properties

    var fcmToken: String?

    /// Last token we successfully pushed to the backend. Used to avoid redundant
    /// `/auth` calls when Firebase hands us the same token on every cold launch.
    private var lastSyncedToken: String?

    /// Observer token for the `FCMTokenUpdated` subscription so we can remove
    /// it deterministically (though in practice this singleton lives forever).
    private var fcmTokenObserver: NSObjectProtocol?

    /// Observer token for `UIApplication.didBecomeActiveNotification`, used to
    /// re-check notification permissions whenever the app returns to the
    /// foreground (see `subscribeToAppForeground()`).
    private var appActiveObserver: NSObjectProtocol?

    /// Last known `UNAuthorizationStatus`, used by the foreground observer to
    /// detect when the user has changed their Notifications permission in
    /// Settings while the app was backgrounded. `nil` until the first check.
    private var lastKnownAuthStatus: UNAuthorizationStatus?

    // MARK: - Configure Firebase Messaging

    func configure() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        subscribeToFCMTokenUpdates()
        subscribeToAppForeground()
        requestNotificationAuthorization()
    }

    // MARK: - Backend Sync

    /// Sync FCM token refreshes to the backend whenever Firebase rotates the
    /// token mid-session. Without this, the only time the backend learns the
    /// token is at login — so a user whose token rotated (reinstall, restore
    /// from backup, periodic rotation) would silently stop receiving push
    /// until their next sign-in.
    private func subscribeToFCMTokenUpdates() {
        // Avoid installing multiple observers if `configure()` is somehow
        // invoked more than once.
        if fcmTokenObserver != nil { return }

        fcmTokenObserver = NotificationCenter.default.addObserver(
            forName: Constants.Notifications.FCMTokenUpdated,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            guard let token = note.userInfo?["token"] as? String, !token.isEmpty else { return }
            // Skip if the backend already has this exact value.
            guard token != self.lastSyncedToken else { return }
            self.lastSyncedToken = token
            Task {
                await GoogleAuthManager.shared.updateFCMTokenOnBackend(token)
            }
        }
    }

    /// Re-run `requestNotificationAuthorization()` whenever the app returns
    /// to the foreground.
    ///
    /// This closes the gap where a user initially denies notifications, then
    /// later enables them from Settings → <App> → Notifications while the
    /// app is merely backgrounded (not force-quit). iOS gives us no direct
    /// hook for the Settings toggle, but `didBecomeActive` is the next
    /// reliable signal that we should re-read the current authorization
    /// status. If the user is now authorized, `registerForRemoteNotifications`
    /// kicks off the APNs → FCM chain, which ultimately fires our
    /// `FCMTokenUpdated` observer and pushes the fresh token to the backend
    /// — no cold relaunch required.
    ///
    /// Safe to call repeatedly: `requestNotificationAuthorization()` branches
    /// on `getNotificationSettings()` and performs idempotent work in every
    /// branch (no duplicate system prompts, `registerForRemoteNotifications`
    /// is cheap, denied paths just log).
    private func subscribeToAppForeground() {
        if appActiveObserver != nil { return }

        appActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            print("🔔 [FirebaseNotificationService] App became active — re-checking notification auth…")

            UNUserNotificationCenter.current().getNotificationSettings { settings in
                let newStatus = settings.authorizationStatus
                let previous = self.lastKnownAuthStatus
                self.lastKnownAuthStatus = newStatus

                if let previous, previous != newStatus {
                    print("🔔 [FirebaseNotificationService] Notification authorization changed while backgrounded: \(previous.debugDescription) → \(newStatus.debugDescription). (User likely toggled Settings → Notifications.)")
                } else {
                    print("🔔 [FirebaseNotificationService] Notification authorization unchanged: \(newStatus.debugDescription).")
                }

                // Always re-run the existing logic; it's idempotent and is the
                // piece that actually calls `registerForRemoteNotifications`
                // when the status is (now) authorized.
                self.requestNotificationAuthorization()
            }
        }
    }

    // MARK: - Request Notification Authorization

    private func requestNotificationAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
                    if let error = error {
                        self.logger.error("Error requesting notifications permission: \(error)")
                    } else if granted {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    } else {
                        self.logger.log("Notifications permission denied.")
                    }
                }
            case .authorized, .provisional:
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            case .denied:
                self.logger.log("Notifications permission denied. Cannot register for remote notifications.")
            case .ephemeral:
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                self.logger.log("App has ephemeral authorization for notifications.")
            @unknown default:
                break
            }
        }
    }

    // MARK: - Get FCM Registration Token

    func getFCMRegToken() async -> String? {
        return await withCheckedContinuation { continuation in
            Messaging.messaging().token { token, error in
                print("🔑 FCM token: \(token ?? "nil")")
                if let error = error {
                    self.logger.error("Error fetching FCM registration token: \(error)")
                    continuation.resume(returning: nil)
                } else {
                    self.fcmToken = token
                    continuation.resume(returning: token)
                }
            }
        }
    }


    // MARK: - Monitor FCM Reg Token

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let token = fcmToken ?? ""
        self.fcmToken = token
        NotificationCenter.default.post(
            name: Constants.Notifications.FCMTokenUpdated,
            object: nil,
            userInfo: ["token": token]
        )
    }

    // MARK: - Handle Notification Responses

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let navigationId = response.notification.request.content.userInfo["navigationId"] as? String {
            navigateToScreen(with: navigationId)
        }

        completionHandler()
    }

    // MARK: - Helpers

    private func navigateToScreen(with navigationId: String) {
        // TODO: Deeplinking
        FirestoreManager.shared.logger.error("Navigating to screen with ID: \(navigationId)")
    }
}

private extension UNAuthorizationStatus {
    /// Human-readable label for debug logs. `UNAuthorizationStatus` is an
    /// `Int`-backed enum so its default `String(describing:)` prints numbers.
    var debugDescription: String {
        switch self {
        case .notDetermined: return "notDetermined"
        case .denied: return "denied"
        case .authorized: return "authorized"
        case .provisional: return "provisional"
        case .ephemeral: return "ephemeral"
        @unknown default: return "unknown(\(rawValue))"
        }
    }
}

