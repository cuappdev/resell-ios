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

    @Published private var tabPaths: [[Route]] = Array(
        repeating: [],
        count: Tab.allCases.count
    )
    @Published var activeTab: Int = Tab.home.rawValue

    /// Navigation path of whichever tab is on screen. Every existing call site
    /// (`push`, `pop`, `popToRoot`, …) reads and writes through this, so the
    /// per-tab split is invisible to them.
    var path: [Route] {
        get { tabPaths[activeIndex] }
        set { tabPaths[activeIndex] = newValue }
    }

    private var activeIndex: Int {
        tabPaths.indices.contains(activeTab) ? activeTab : Tab.home.rawValue
    }

    /// Binding for one tab's `NavigationStack`, including the tabs that are
    /// currently off screen but still mounted.
    func pathBinding(for tab: Int) -> Binding<[Route]> {
        Binding(
            get: { self.tabPaths.indices.contains(tab) ? self.tabPaths[tab] : [] },
            set: { newValue in
                guard self.tabPaths.indices.contains(tab) else { return }
                self.tabPaths[tab] = newValue
            }
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
        tabPaths = Array(repeating: [], count: Tab.allCases.count)
        activeTab = Tab.home.rawValue
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

