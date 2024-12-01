//
//  ResellApp.swift
//  Resell
//
//  Created by Richie Sun on 9/9/24.
//

import GoogleSignIn
import Kingfisher
import SwiftUI

@main
struct ResellApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: ResellAppDelegate

    var body: some Scene {
        WindowGroup {
            MainView()
                .onAppear(perform: {
                    // this makes sure that we are setting the app to the app delegate as soon as the main view appears
                    appDelegate.app = self
                })
        }
    }
}
