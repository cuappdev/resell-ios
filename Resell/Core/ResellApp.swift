//
//  ResellApp.swift
//  Resell
//
//  Created by Richie Sun on 9/9/24.
//

import GoogleSignIn
import Firebase
import SwiftUI

@main
struct ResellApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

func requestNotificationPermission() {
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

    func showPermissionError() {
        // TODO: Implement ToastStyle Message
    }
}

