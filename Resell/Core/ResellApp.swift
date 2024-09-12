//
//  ResellApp.swift
//  Resell
//
//  Created by Richie Sun on 9/9/24.
//

import GoogleSignIn
import SwiftUI

@main
struct ResellApp: App {
    var body: some Scene {
        WindowGroup {
            LoginView()
                .onAppear {
                    let signInConfig = GIDConfiguration.init(clientID: Keys.googleClientID)
                    GIDSignIn.sharedInstance.configuration = signInConfig
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        // Check if `user` exists; otherwise, do something with `error`
                    }
                }
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
