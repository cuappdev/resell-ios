//
//  MainView.swift
//  Resell
//
//  Created by Richie Sun on 9/11/24.
//

import GoogleSignIn
import SwiftUI

struct MainView: View {

    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        ZStack {
            if viewModel.userDidLogin {
                HomeView()
            } else {
                LoginView(userDidLogin: $viewModel.userDidLogin)
            }
        }
        .onAppear {
            let signInConfig = GIDConfiguration.init(clientID: Keys.googleClientID)
            GIDSignIn.sharedInstance.configuration = signInConfig
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                if let user {
                    viewModel.userDidLogin = true
                }
                // Check if `user` exists; otherwise, do something with `error`
            }
        }
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
    }
}
