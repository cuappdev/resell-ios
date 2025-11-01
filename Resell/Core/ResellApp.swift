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
          //TODO: Refactor...
          HomeViewModel.shared.configure(mainViewModel: mainViewModel)
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
//                .onAppear(perform: {
//                    // this makes sure that we are setting the app to the app delegate as soon as the main view appears
//                    appDelegate.app = self
//                })
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
