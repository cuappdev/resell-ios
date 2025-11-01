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
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if !granted {
                        showPermissionError()
                    }
                }
            case .denied:
                showPermissionError()
            case .authorized, .provisional, .ephemeral:
                break
            @unknown default:
                break
            }
        }
    }

    /// Show a notification permission error (replace with actual UI if needed)
    private func showPermissionError() {
        DispatchQueue.main.async {
            print("Notifications permission denied. Implement a toast-style message or alert.")
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

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Handle foreground notifications
        completionHandler([.sound, .badge])
    }
}
