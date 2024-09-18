//
//  MainView.swift
//  Resell
//
//  Created by Richie Sun on 9/11/24.
//

import GoogleSignIn
import SwiftUI

struct MainView: View {

    // MARK: - Properties

    @State var selection = 0
    @StateObject private var viewModel = MainViewModel()

    // MARK: - UI

    var body: some View {
        ZStack {
            if viewModel.userDidLogin {
                TabView(selection: $selection) {
                    HomeView()
                        .tabItem {
                            TabViewIcon(index: 0, selectionIndex: selection)
                        }.tag(0)

                    SavedView()
                        .tabItem {
                            TabViewIcon(index: 1, selectionIndex: selection)
                        }.tag(1)

                    ChatsView()
                        .tabItem {
                            TabViewIcon(index: 2, selectionIndex: selection)
                        }.tag(2)

                    ProfileView()
                        .tabItem {
                            TabViewIcon(index: 3, selectionIndex: selection)
                        }.tag(3)
                }
                .transition(.opacity)
                .animation(.easeInOut, value: viewModel.userDidLogin)
            } else {
                LoginView(userDidLogin: $viewModel.userDidLogin)
                    .transition(.opacity)
                    .animation(.easeInOut, value: viewModel.userDidLogin)
            }
        }
        .onAppear {
            let signInConfig = GIDConfiguration.init(clientID: Keys.googleClientID)
            GIDSignIn.sharedInstance.configuration = signInConfig
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
//                if let user {
//                    viewModel.userDidLogin = true
//                }
                // Check if `user` exists; otherwise, do something with `error`
            }
        }
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
    }
}
