//
//  MainView.swift
//  Resell
//
//  Created by Richie Sun on 9/11/24.
//

import GoogleSignIn
import SwiftUI

import GoogleSignIn
import SwiftUI

struct MainView: View {

    // MARK: - Properties

    @State var selection = 0
    @StateObject private var mainViewModel = MainViewModel()
    @StateObject private var router = Router()

    // MARK: - UI

    var body: some View {
        ZStack {
            if mainViewModel.userDidLogin {
                MainTabView(isHidden: $mainViewModel.hidesTabBar, selection: $selection)
                    .transition(.opacity)
                    .animation(.easeInOut, value: mainViewModel.userDidLogin)
                    .environmentObject(router)
            } else {
                LoginView(userDidLogin: $mainViewModel.userDidLogin)
                    .transition(.opacity)
                    .animation(.easeInOut, value: mainViewModel.userDidLogin)
                    .environmentObject(router)
            }
        }
        .background(Constants.Colors.white)
        .environmentObject(mainViewModel)
        .onAppear {
            let signInConfig = GIDConfiguration.init(clientID: Keys.googleClientID)
            GIDSignIn.sharedInstance.configuration = signInConfig
            mainViewModel.restoreSignIn()
            mainViewModel.setupNavBar()
            mainViewModel.hidesTabBar = false
        }
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
    }
}
