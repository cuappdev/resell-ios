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
import DeviceCheck
import Kingfisher

@main
struct ResellApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var mainViewModel = MainViewModel()

    init() {
        // NOTE: Do NOT touch `mainViewModel` here. Reading the wrappedValue of
        // a `@StateObject` inside `App.init()` is undefined behavior — the
        // SwiftUI storage isn't bound yet, so the instance you'd hand to a
        // singleton becomes a different one than the view tree later uses.
        // The previous `HomeViewModel.shared.configure(mainViewModel:)` call
        // has been moved into `MainView.onAppear` so it operates on the same
        // `MainViewModel` instance the view tree actually observes.
        setupKingfisher()
    }
    
    private func setupKingfisher() {
        // Limit concurrent downloads to 4 (prevents CPU overload)
        ImageDownloader.default.sessionConfiguration.httpMaximumConnectionsPerHost = 4
        
        // Enable progressive loading for better UX
        ImageDownloader.default.sessionConfiguration.timeoutIntervalForRequest = 15
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(mainViewModel)
                .environmentObject(HomeViewModel.shared)
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
        Task {
            await FirebaseNotificationService.shared.getFCMRegToken()
        }
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {

        Messaging.messaging().appDidReceiveMessage(userInfo)
        FirestoreManager.shared.logger.log("Received remote notification: \(userInfo)")

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
