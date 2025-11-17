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

    // MARK: - Configure Firebase Messaging

    func configure() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        requestNotificationAuthorization()
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
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
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

