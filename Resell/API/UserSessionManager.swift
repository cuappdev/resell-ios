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

    // MARK: - Init

    private init() {
        self.accessToken = KeychainManager.shared.get(forKey: "accessToken")
        self.googleID = KeychainManager.shared.get(forKey: "googleID")
        self.userID = KeychainManager.shared.get(forKey: "userID")
    }

    // MARK: - Functions

    func logout() {
        accessToken = nil
        userID = nil
    }
}
