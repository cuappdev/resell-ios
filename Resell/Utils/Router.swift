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
        case messages(ChatsViewModel)
        case newListingDetails
        case newListingImages
        case newRequest
        case profile
        case productDetails(String)
        case reportOptions
        case reportDetails
        case reportConfirmation
        case settings(Bool)
        case blockedUsers
        case feedback
        case notifications
        case setupProfile
        case venmo

        func hash(into hasher: inout Hasher) {
            switch self {
            case .login: hasher.combine("login")
            case .home: hasher.combine("home")
            case .saved: hasher.combine("saved")
            case .chats: hasher.combine("chats")
            case .messages: hasher.combine("messages")
            case .newListingDetails: hasher.combine("newListingDetails")
            case .newListingImages: hasher.combine("newListingImages")
            case .newRequest: hasher.combine("newRequest")
            case .profile: hasher.combine("profile")
            case .productDetails(let id): hasher.combine("productDetails/\(id)")
            case .reportOptions: hasher.combine("reportOptions")
            case .reportDetails: hasher.combine("reportDetails")
            case .reportConfirmation: hasher.combine("reportConfirmation")
            case .settings(let isAccountSettings): hasher.combine("settings/\(isAccountSettings ? "account" : "general")")
            case .blockedUsers: hasher.combine("blockedUsers")
            case .feedback: hasher.combine("feedback")
            case .notifications: hasher.combine("notifications")
            case .setupProfile: hasher.combine("setupProfile")
            case .venmo: hasher.combine("venmo")
            }
        }

        // Equatable conformance for cases with associated values
        static func ==(lhs: Route, rhs: Route) -> Bool {
            switch (lhs, rhs) {
            case (.login, .login),
                (.home, .home),
                (.saved, .saved),
                (.chats, .chats),
                (.messages, .messages),
                (.newListingDetails, .newListingDetails),
                (.newListingImages, .newListingImages),
                (.newRequest, .newRequest),
                (.profile, .profile),
                (.reportOptions, .reportOptions),
                (.reportDetails, .reportDetails),
                (.reportConfirmation, .reportConfirmation),
                (.blockedUsers, .blockedUsers),
                (.feedback, .feedback),
                (.notifications, .notifications),
                (.setupProfile, .setupProfile),
                (.venmo, .venmo):
                return true
            case let (.productDetails(id1), .productDetails(id2)):
                return id1 == id2
            case let (.settings(isAccountSettings1), .settings(isAccountSettings2)):
                return isAccountSettings1 == isAccountSettings2
            default:
                return false
            }
        }
    }

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func popToRoot() {
        path.removeAll()
    }

    func lastPushedView() -> Route {
        return path.last ?? .home
    }
}

