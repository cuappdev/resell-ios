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
    @Environment(\.scenePhase) private var scenePhase

    @EnvironmentObject private var mainViewModel: MainViewModel
    @StateObject private var router = Router()
    @StateObject private var chatsViewModel = ChatsViewModel()
    @StateObject private var newListingViewModel = NewListingViewModel()
    @StateObject private var onboardingViewModel = SetupProfileViewModel()
    @StateObject private var reportViewModel = ReportViewModel()
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var appVersionService = AppVersionService()

    // MARK: - UI

    var body: some View {
        MainTabView(isHidden: $mainViewModel.hidesTabBar, selection: $mainViewModel.selection)
            .environmentObject(searchViewModel)
            .environmentObject(router)
            .environmentObject(mainViewModel)
            .environmentObject(chatsViewModel)
            .environmentObject(newListingViewModel)
            .environmentObject(onboardingViewModel)
            .environmentObject(reportViewModel)
            .background(Constants.Colors.white)
            .preferredColorScheme(.light)
            .onAppear {
                let signInConfig = GIDConfiguration.init(clientID: Keys.googleClientID)
                GIDSignIn.sharedInstance.configuration = signInConfig
                mainViewModel.restoreSignIn()
                mainViewModel.setupNavBar()
                mainViewModel.hidesTabBar = false
            }
            .task {
                await appVersionService.checkIfUpdateRequired()
            }
            .onChange(of: scenePhase) { newValue in
                guard newValue == .active else { return }
                Task { await appVersionService.checkIfUpdateRequired() }
            }
            .fullScreenCover(isPresented: Binding(
                get: { appVersionService.isUpdateRequired },
                set: { _ in }
            )) {
                ForceUpdateView(
                    installedVersion: appVersionService.installedVersion,
                    requiredVersion: appVersionService.requiredVersion,
                    appStoreId: Keys.appStoreId,
                    onTryAgain: {
                        Task { await appVersionService.checkIfUpdateRequired() }
                    }
                )
                .interactiveDismissDisabled(true)
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
                
                handleIncomingURL(url)
            }
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "resell", url.host == "product" else { return }
        
        let postId = url.lastPathComponent
        
        Task {
            do {
                let postResponse = try await NetworkManager.shared.getPostByID(id: postId)
                let fetchedPost = postResponse.post
                
                await MainActor.run {
                    router.popToRoot()
                    
                    if let post = fetchedPost {
                        router.push(.productDetails(post))
                    }
                }
            } catch {
                print("Failed to load post from deep link: \(error.localizedDescription)")
            }
        }
    }
}
