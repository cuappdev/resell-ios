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

    // MARK: - Init

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(logout),
            name: Constants.Notifications.LogoutUser,
            object: nil
        )
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

    @objc func logout() {
        // Clear any cached data
        clearUserData()
        
        // Sign out from auth manager
        GoogleAuthManager.shared.signOut()
        
        // Update UI state
        withAnimation { userDidLogin = false }
        
        // Reset to home tab
        selection = 0
    }
    
    /// Clear user-specific cached data when logging out
    private func clearUserData() {
        clearImageCaches()
    }
    
    private func clearImageCaches() {
        // Clear Kingfisher cache if using it
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache()
    }

    func restoreSignIn() {
        Task {
            hidesSignInButton = true
            do {
                try await GoogleAuthManager.shared.refreshSignInIfNeeded()

                await MainActor.run {
                    withAnimation { hidesSignInButton = true }
                    withAnimation { userDidLogin = true }
                }
            } catch {
                // Session token has expired and Google Sign-In retrieval has failed
                await MainActor.run {
                    clearUserData()
                    GoogleAuthManager.shared.signOut()
                    
                    withAnimation { hidesSignInButton = false }
                    withAnimation { userDidLogin = false }
                }
                GoogleAuthManager.shared.logger.log("User Session Has Expired or Google Sign-In Failed: \(error)")
            }
        }
    }

}
