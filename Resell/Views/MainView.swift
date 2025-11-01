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

    @StateObject private var mainViewModel = MainViewModel()
    @StateObject private var router = Router()
    @StateObject private var chatsViewModel = ChatsViewModel()
    @StateObject private var newListingViewModel = NewListingViewModel()
    @StateObject private var onboardingViewModel = SetupProfileViewModel()
    @StateObject private var reportViewModel = ReportViewModel()

    // MARK: - UI

    var body: some View {
        MainTabView(isHidden: $mainViewModel.hidesTabBar, selection: $mainViewModel.selection)
            .environmentObject(router)
            .environmentObject(mainViewModel)
            .environmentObject(chatsViewModel)
            .environmentObject(newListingViewModel)
            .environmentObject(onboardingViewModel)
            .environmentObject(reportViewModel)
            .background(Constants.Colors.white)
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
