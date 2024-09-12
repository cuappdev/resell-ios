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

    private let tabItems = ["home", "bookmark", "messages", "user"]

    // MARK: - UI

    var body: some View {
        ZStack {
            if viewModel.userDidLogin {
                TabView(selection: $selection) {
                    HomeView()
                        .tabItem {
                            Image(selection == 0 ? "\(tabItems[0])-selected" : tabItems[0])
                        }.tag(0)

                    SavedView()
                        .tabItem {
                            Image(selection == 1 ? "\(tabItems[1])-selected" : tabItems[1])
                        }.tag(1)

                    ChatsView()
                        .tabItem {
                            Image(selection == 2 ? "\(tabItems[2])-selected" : tabItems[2])
                        }.tag(2)

                    ProfileView()
                        .tabItem {
                            Image(selection == 3 ? "\(tabItems[3])-selected" : tabItems[3])
                        }.tag(3)
                }
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
