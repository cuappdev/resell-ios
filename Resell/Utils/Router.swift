//
//  Router.swift
//  Resell
//
//  Created by Richie Sun on 10/20/24.
//

import SwiftUI

class Router: ObservableObject {
    @Published var path: [Route] = []

    enum Route: Hashable {
        case login
        case home
        case saved
        case chats
        case editProfile
        case messages
        case newListingDetails
        case newListingImages
        case newRequest
        case notifications
        case profile(String)
        case productDetails(String)
        case reportOptions
        case reportDetails
        case reportConfirmation
        case search
        case settings(Bool)
        case blockedUsers
        case feedback
        case notificationsSettings
        case setupProfile
        case venmo
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

    func lastPushedView() -> Route {
        return path.last ?? .home
    }
}

