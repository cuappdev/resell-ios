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
                .onAppear {
                    requestNotificationPermission()
                }
        }
    }

    /// Request user permission for notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                // Request notification permissions
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
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
}

/// AppDelegate for Firebase and notification handling
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self // Set delegate for notifications
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Set APNs token for Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        // Handle custom data from notification if needed
        if let customData = userInfo["customKey"] as? String {
            FirestoreManager.shared.logger.log("Received custom data: \(customData)")
        }

        completionHandler(.newData)
    }

    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Handle foreground notifications
        completionHandler([.sound, .badge])
    }
}
