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
        case profile
        case productDetails(String)
        case report
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
}