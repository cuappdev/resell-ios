//
//  MainViewModel.swift
//  Resell
//
//  Created by Richie Sun on 9/11/24.
//

import FirebaseMessaging
import Kingfisher
import SwiftUI

@MainActor
class MainViewModel: ObservableObject {

    // MARK: - Properties

    @Published var hidesTabBar: Bool = false
    @Published var userDidLogin: Bool = false

    @Published var selection = 0

    var hidesSignInButton = true

    // MARK: - Persistent Storage

    @AppStorage("chatNotificationsEnabled") var chatNotificationsEnabled: Bool = true
    @AppStorage("newListingsEnabled") var newListingsEnabled: Bool = true
    @AppStorage("userSearchHistory") private var storedHistoryData: String = ""
    @AppStorage("blockedUsers") private var blockedUsersStorage: String = "[]"

    // Decoded search history array from persistent storage
    var searchHistory: [String] {
        get {
            decodeHistory(from: storedHistoryData)
        }
        set {
            storedHistoryData = encodeHistory(newValue)
        }
    }

    // MARK: - Functions

    func toggleAllNotifications(paused: Bool) {
        chatNotificationsEnabled = !paused
        newListingsEnabled = !paused
    }

    func saveSearchQuery(_ query: String) {
        var history = searchHistory

        history.removeAll { $0 == query }

        history.insert(query, at: 0)

        if history.count > 10 {
            history.removeLast()
        }

        searchHistory = history
    }

    private func encodeHistory(_ history: [String]) -> String {
        guard let data = try? JSONEncoder().encode(history),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return jsonString
    }

    private func decodeHistory(from jsonString: String) -> [String] {
        guard let data = jsonString.data(using: .utf8),
              let history = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return history
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
                hidesSignInButton = true

                if let _ = UserSessionManager.shared.accessToken,
                   let _ = UserSessionManager.shared.userID {
                    // Validate the access token by prefetching saved post URLs
                    let urls = try await NetworkManager.shared.getSavedPosts().posts.compactMap { $0.images.first }
                    let prefetcher = ImagePrefetcher(urls: urls)
                    prefetcher.start()

                    try? GoogleAuthManager.shared.getOAuthToken { token in
                        UserSessionManager.shared.oAuthToken = token
                    }

                    await MainActor.run {
                        withAnimation { userDidLogin = true }
                    }
                } else if let googleID = UserSessionManager.shared.googleID {
                    // Re-authenticate using Google ID
                    let user = try await NetworkManager.shared.getUserByGoogleID(googleID: googleID).user
                    var userSession = try await NetworkManager.shared.getUserSession(id: user.id).sessions.first

                    if !(userSession?.active ?? false) {
                        userSession = try await NetworkManager.shared.refreshToken()
                    }

                    UserSessionManager.shared.accessToken = userSession?.accessToken
                    UserSessionManager.shared.refreshToken = userSession?.refreshToken
                    UserSessionManager.shared.googleID = googleID
                    UserSessionManager.shared.userID = user.id
                    UserSessionManager.shared.email = user.email
                    UserSessionManager.shared.profileURL = user.photoUrl
                    UserSessionManager.shared.name = "\(user.givenName) \(user.familyName)"

                    withAnimation { userDidLogin = true }
                } else {
                    // Attempt to restore Google Sign-In
                    let user = try await GoogleAuthManager.shared.restorePreviousSignIn()
                    guard let user,
                          let googleID = user.userID else {
                        await MainActor.run {
                            withAnimation { hidesSignInButton = false }
                            withAnimation { userDidLogin = false }
                        }
                        return
                    }

                    // Fetch user data from the server using Google credentials
                    let serverUser = try await NetworkManager.shared.getUserByGoogleID(googleID: googleID).user
                    var userSession = try await NetworkManager.shared.getUserSession(id: serverUser.id).sessions.first

                    if !(userSession?.active ?? false) {
                        userSession = try await NetworkManager.shared.refreshToken()
                    }

                    UserSessionManager.shared.accessToken = userSession?.accessToken
                    UserSessionManager.shared.refreshToken = userSession?.refreshToken
                    UserSessionManager.shared.googleID = googleID
                    UserSessionManager.shared.userID = serverUser.id
                    UserSessionManager.shared.email = serverUser.email
                    UserSessionManager.shared.profileURL = serverUser.photoUrl
                    UserSessionManager.shared.name = "\(serverUser.givenName) \(serverUser.familyName)"

                    try? GoogleAuthManager.shared.getOAuthToken { token in
                        UserSessionManager.shared.oAuthToken = token
                    }

                    withAnimation { userDidLogin = true }
                }
            } catch {
                // Session token has expired or re-authentication failed
                withAnimation { hidesSignInButton = false }
                withAnimation { userDidLogin = false }
                NetworkManager.shared.logger.log("User Session Has Expired or Google Sign-In Failed: \(error)")
            }
        }
    }


}
