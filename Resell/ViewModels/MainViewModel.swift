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

    /// When true, the tab bar minimize behavior is .never, which forces the bar to
    /// expand. Kept false ("armed", .onScrollDown) at rest so any downward scroll
    /// minimizes the bar natively at any speed; crossing back above the top
    /// breakpoint fires a short .never pulse to force expansion, then re-arms.
    @Published var expandsTabBar: Bool = false

    /// Mirrors the tab bar's actual expanded/minimized presentation so floating
    /// controls (the add button) stay exactly in sync with it.
    @Published var isTabBarMinimized = false

    /// Scroll offset below which the bar expands / above which it minimizes.
    static let tabBarExpandBreakpoint: CGFloat = 16
    static let tabBarMinimizeBreakpoint: CGFloat = 24

    private var scrollIsAtTop = true
    private var rearmTask: Task<Void, Never>?

    /// Forces the tab bar to expand, then re-arms minimize-on-scroll shortly after.
    func pulseExpandTabBar() {
        rearmTask?.cancel()
        if isTabBarMinimized {
            isTabBarMinimized = false
        }
        if !expandsTabBar {
            expandsTabBar = true
        }
        rearmTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.45))
            guard !Task.isCancelled else { return }
            self?.expandsTabBar = false
        }
    }

    /// Called when the user taps the minimized tab bar pill — the system expands
    /// the bar itself; this keeps our mirrored state (and the add button) in sync.
    func handleManualTabBarExpansion() {
        if isTabBarMinimized {
            isTabBarMinimized = false
        }
    }

    /// Drives the tab bar from a tab root's scroll offset: expand when the scroll
    /// crosses above the top breakpoint; past the breakpoint, minimize only on
    /// downward movement (mirroring .onScrollDown, so a manually expanded bar
    /// stays expanded until the user actually scrolls down again).
    func updateTabBarForScroll(offset: CGFloat, previousOffset: CGFloat) {
        if offset < Self.tabBarExpandBreakpoint {
            if isTabBarMinimized {
                isTabBarMinimized = false
            }
            if !scrollIsAtTop {
                scrollIsAtTop = true
                pulseExpandTabBar()
            }
        } else if offset > Self.tabBarMinimizeBreakpoint {
            if scrollIsAtTop {
                scrollIsAtTop = false
            }
            rearmTask?.cancel()
            if expandsTabBar {
                expandsTabBar = false
            }
            if offset > previousOffset + 2, !isTabBarMinimized {
                isTabBarMinimized = true
            }
        }
    }

    @Published var hidesSignInButton = true

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

    @objc func logout() {
        // Clear any cached data
        clearUserData()
        
        // Sign out from auth manager
        GoogleAuthManager.shared.signOut()
        
        // Update UI state
        withAnimation { userDidLogin = false }
        withAnimation { hidesSignInButton = false }
        
        // Reset to home tab
        selection = 0
    }
    
    /// Clear user-specific cached data when logging out
    private func clearUserData() {
        clearImageCaches()
        HomeViewModel.shared.clearCache()
        SearchViewModel.shared.clearCache()
        CurrentUserProfileManager.shared.clearCache()
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
