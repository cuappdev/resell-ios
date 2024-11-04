//
//  MainViewModel.swift
//  Resell
//
//  Created by Richie Sun on 9/11/24.
//

import Kingfisher
import SwiftUI

@MainActor
class MainViewModel: ObservableObject {

    // MARK: - Properties

    @Published var hidesTabBar: Bool = false
    @Published var userDidLogin: Bool = false

    // MARK: - Persistent Storage

    @AppStorage("chatNotificationsEnabled") var chatNotificationsEnabled: Bool = true
    @AppStorage("newListingsEnabled") var newListingsEnabled: Bool = true

    // MARK: - Functions

    func toggleAllNotifications(paused: Bool) {
        chatNotificationsEnabled = !paused
        newListingsEnabled = !paused
    }

    func setupNavBar() {
        let backButtonImage = UIImage(named: "chevron.left")?
            .resized(to: CGSize(width: 38, height: 24))
            .withRenderingMode(.alwaysOriginal)
            .withTintColor(.black)
        let appearance = UINavigationBarAppearance()
        appearance.backButtonAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: -100, vertical: 0)
        appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.setBackIndicatorImage(backButtonImage, transitionMaskImage: backButtonImage)
        UINavigationBar.appearance().standardAppearance = appearance
    }

    func restoreSignIn() {
        Task {
            do {
                if let _ = UserSessionManager.shared.accessToken,
                   let _ = UserSessionManager.shared.userID {
                    // Verify that the accessToken is valid by attempting to prefetch post URLs
                    let urls = try await NetworkManager.shared.getAllPosts().posts.compactMap { $0.images.first }
                    let prefetcher = ImagePrefetcher(urls: urls)
                    prefetcher.start()

                    withAnimation { userDidLogin = true }
                } else if let googleID = UserSessionManager.shared.googleID {
                    // If accessToken is not available, try to re-authenticate using googleID
                    let user = try await NetworkManager.shared.getUserByGoogleID(googleID: googleID).user
                    let userSession = try await NetworkManager.shared.getUserSession(id: user.id).sessions.first

                    UserSessionManager.shared.accessToken = userSession?.accessToken
                    UserSessionManager.shared.googleID = googleID
                    UserSessionManager.shared.userID = user.id

                    withAnimation { userDidLogin = true }
                } else {
                    withAnimation { userDidLogin = false }
                }
            } catch {
                // Session Token has expired
                withAnimation { userDidLogin = false }
                NetworkManager.shared.logger.log("User Session Has Expired")
            }
        }
    }
}
