//
//  Router.swift
//  Resell
//
//  Created by Richie Sun on 10/20/24.
//

import SwiftUI

enum FollowListType {
    case followers
    case following
}

class Router: ObservableObject {

    /// Bottom tab bar slots. Each one owns an independent navigation stack, so
    /// switching tabs leaves the stack you were in exactly where you left it.
    enum Tab: Int, CaseIterable {
        case home, explore, sell, chats, profile
    }

    @Published private var tabPaths: [Tab: [Route]] = [:]
    @Published var activeTab: Tab = .home

    /// Navigation path of whichever tab is on screen. Every existing call site
    /// (`push`, `pop`, `popToRoot`, …) reads and writes through this, so the
    /// per-tab split is invisible to them.
    var path: [Route] {
        get { tabPaths[activeTab, default: []] }
        set { tabPaths[activeTab] = newValue }
    }

    /// Binding for one tab's `NavigationStack`, including the tabs that are
    /// currently off screen but still mounted.
    func pathBinding(for tab: Tab) -> Binding<[Route]> {
        Binding(
            get: { self.tabPaths[tab, default: []] },
            set: { self.tabPaths[tab] = $0 }
        )
    }

    enum Route: Hashable {
        case login
        case home
        case saved
        case recentlyViewed
        case dailyPicks
        case trending(FilterCategory)
        case chats
        case editProfile
        case messages(chatInfo: ChatInfo)
        case newListingDetails
        case newListingImages
        case newRequest
        case notifications
        case filters
        case profile(String)
        case productDetails(Post)
        case reportOptions(type: String, id: String)
        case reportDetails
        case reportConfirmation
        case discover
        case detailedFilter(FilterCategory)
        case search(String?) //
        case recentlySearched
        case settings(Bool)
        case blockedUsers
        case feedback
        case setupProfile
        case venmo
        case availability
        case followList(userID: String, username: String, initialTab: FollowListType)
        case completedTransaction(Transaction)
    }

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func popTo(_ route: Route) {
        if let index = path.firstIndex(of: route) {
            path.removeLast(path.count - index - 1)
        }
    }

    func popToRoot() {
        path.removeAll()
    }

    /// Clears every tab's stack and returns to Home. Used on logout so the next
    /// account doesn't inherit the previous one's navigation.
    func reset() {
        tabPaths = [:]
        activeTab = .home
    }

    func lastPushedView() -> Route {
        return path.last ?? .home
    }
    
//    func navigateToProductDetails(post: Post) {
//        if let existingIndex = path.firstIndex(where: {
//            if case .productDetails = $0 {
//                return true
//            }
//            return false
//        }) {
//            path[existingIndex] = .productDetails(post)
//            popTo(path[existingIndex])
//        } else {
//            push(.productDetails(post))
//        }
//    }
}

