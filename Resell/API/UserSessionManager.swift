//
//  UserSessionManager.swift
//  Resell
//
//  Created by Richie Sun on 11/3/24.
//

import Foundation
import os
import SwiftUI

class UserSessionManager: ObservableObject {

    // MARK: - Singleton Instance

    static let shared = UserSessionManager()

    // MARK: - Properties

    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.cornellappdev.Resell", category: "UserSession")

    @Published var accessToken: String? {
        didSet {
            if let token = accessToken {
                KeychainManager.shared.save(token, forKey: "accessToken")
            } else {
                KeychainManager.shared.delete(forKey: "accessToken")
            }
        }
    }

    @Published var googleID: String? {
        didSet {
            if let token = accessToken {
                KeychainManager.shared.save(token, forKey: "googleID")
            } else {
                KeychainManager.shared.delete(forKey: "googleID")
            }
        }
    }

    @Published var userID: String? {
        didSet {
            if let id = userID {
                KeychainManager.shared.save(id, forKey: "userID")
            } else {
                KeychainManager.shared.delete(forKey: "userID")
            }
        }
    }

    @Published var email: String? {
        didSet {
            if let email {
                KeychainManager.shared.save(email, forKey: "email")
            } else {
                KeychainManager.shared.delete(forKey: "email")
            }
        }
    }

    @Published var profileURL: URL? {
        didSet {
            if let profileURL {
                KeychainManager.shared.save(profileURL.absoluteString, forKey: "profileURL")
            } else {
                KeychainManager.shared.delete(forKey: "profileURL")
            }
        }
    }

    @Published var name: String? {
        didSet {
            if let name {
                KeychainManager.shared.save(name, forKey: "name")
            } else {
                KeychainManager.shared.delete(forKey: "name")
            }
        }
    }

    // MARK: - Init

    private init() {
        self.accessToken = KeychainManager.shared.get(forKey: "accessToken")
        self.googleID = KeychainManager.shared.get(forKey: "googleID")
        self.userID = KeychainManager.shared.get(forKey: "userID")
        self.email = KeychainManager.shared.get(forKey: "email")
        self.profileURL = URL(string: KeychainManager.shared.get(forKey: "profileURL") ?? "")
        self.name = KeychainManager.shared.get(forKey: "name")
    }

    // MARK: - Functions

    func logout() {
        accessToken = nil
        googleID = nil
        userID = nil
        email = nil
        profileURL = nil
        name = nil
    }
}
