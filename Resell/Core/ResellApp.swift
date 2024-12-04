//
//  ResellApp.swift
//  Resell
//
//  Created by Richie Sun on 9/9/24.
//

import Firebase
import FirebaseMessaging
import GoogleSignIn
import SwiftUI
import UserNotifications


@main
struct ResellApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        FirebaseNotificationService.shared.configure()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
        FirebaseNotificationService.shared.getFCMRegToken()
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        guard let email = UserSessionManager.shared.email else { return }

        Messaging.messaging().appDidReceiveMessage(userInfo)
        print("Received remote notification: \(userInfo)")

        if let aps = userInfo["aps"] as? [String: Any],
           let alert = aps["alert"] as? [String: String],
           let title = alert["title"],
           let body = alert["body"],
           let navigationId = userInfo["navigationId"] as? String {

            Task {
                do {
                    guard let token = try await FirestoreManager.shared.getUserFCMToken(email: email) else { return }
                    let authToken = try await GoogleAuthManager.shared.getOAuthToken()

                    try await FirebaseNotificationService.shared.sendNotification(
                        title: title,
                        body: body,
                        recipientToken: token,
                        navigationId: navigationId,
                        authToken: "Bearer \(authToken ?? "")"
                    )

                    print("Notification sent successfully.")
                } catch {
                    print("Error sending notification: \(error.localizedDescription)")
                }
            }
        } else {
            print("Invalid notification payload.")
        }

        completionHandler(.newData)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.sound, .badge])
    }

}
