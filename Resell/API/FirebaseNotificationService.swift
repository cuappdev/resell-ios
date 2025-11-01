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

class FirebaseNotificationService: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {

    // MARK: - Singleton Instance

    static let shared = FirebaseNotificationService()
    var fcmRegToken: String = ""

    private let endpoint = "\(Keys.firebaseURL)/v1/projects/resell-e99a2/messages:send"

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
                        FirestoreManager.shared.logger.error("Error requesting notifications permission: \(error.localizedDescription)")
                    } else if granted {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    } else {
                        FirestoreManager.shared.logger.log("Notifications permission denied.")
                    }
                }
            case .authorized, .provisional:
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            case .denied:
                FirestoreManager.shared.logger.log("Notifications permission denied. Cannot register for remote notifications.")
            case .ephemeral:
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                FirestoreManager.shared.logger.log("App has ephemeral authorization for notifications.")
            @unknown default:
                break
            }
        }
    }

    // MARK: - Get FCM Registration Token

    func getFCMRegToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                FirestoreManager.shared.logger.error("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                self.fcmRegToken = (token)
            }
        }
    }

    // MARK: - Setup FCM Token

    func setupFCMToken() {
        let messaging = Messaging.messaging()
        guard let email = UserSessionManager.shared.email else {
            UserSessionManager.shared.logger.error("Error in MainViewModel: email not found")
            return
        }

        // Check if user has allowed notifications
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task {
                do {
                    let notificationsAllowed = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional

                    // Save the notification status to Firestore
                    try await FirestoreManager.shared.saveNotificationsEnabled(userEmail: email, notificationsEnabled: notificationsAllowed)

                    // Get the FCM token from Firestore
                    let firestoreToken = try await FirestoreManager.shared.getUserFCMToken(email: email)

                    // Get the device token from Firebase Messaging
                    guard let deviceToken = messaging.fcmToken else {
                        FirestoreManager.shared.logger.error("Device FCM token is missing.")
                        return
                    }

                    // Save the device token to Firestore if it's not already there or if it has changed
                    if firestoreToken == nil || firestoreToken != deviceToken {
                        try await FirestoreManager.shared.saveDeviceToken(userEmail: email, deviceToken: deviceToken)
                        FirestoreManager.shared.logger.log("FCM token successfully added for \(email).")
                    }
                } catch {
                    FirestoreManager.shared.logger.error("Error saving notification status or FCM token: \(error.localizedDescription)")
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
        print("User interacted with notification: \(response.notification.request.content.userInfo)")

        if let navigationId = response.notification.request.content.userInfo["navigationId"] as? String {
            navigateToScreen(with: navigationId)
        }

        completionHandler()
    }

    // MARK: - Show Notification

    func sendNotification(
        title: String?,
        body: String?,
        recipientToken: String,
        navigationId: String,
        authToken: String
    ) async throws {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }

        let notification = title != nil && body != nil ? FcmNotification(title: title!, body: body!) : nil
        let notificationData = NotificationData(navigationId: navigationId)
        let message = FcmMessage(token: recipientToken, notification: notification, data: notificationData)
        let fcmBody = FcmBody(message: message)

        let requestBody = try JSONEncoder().encode(fcmBody)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = requestBody

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        print("Notification sent successfully: \(String(data: data, encoding: .utf8) ?? "")")
    }

    // MARK: - Helpers

    private func navigateToScreen(with navigationId: String) {
        // TODO: Deeplinking
        print("Navigating to screen with ID: \(navigationId)")
    }
}

