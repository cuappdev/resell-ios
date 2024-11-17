//
//  User.swift
//  Resell
//
//  Created by Richie Sun on 11/2/24.
//

import Foundation

struct User: Codable {
    let id: String
    let username: String
    let netid: String
    let givenName: String
    let familyName: String
    let admin: Bool
    let photoUrl: URL
    let venmoHandle: String
    let email: String
    let googleId: String
    let bio: String
    let isActive: Bool
    let blocking: [String]?
    let blockers: [String]?
    let reports: [String]?
    let reportedBy: [String]?
    let posts: [Post]?
    let feedbacks: [Feedback]?
}

struct UsersResponse: Codable {
    let users: [User]
}

struct UserResponse: Codable {
    let user: User
}

struct UserSessionData: Codable {
    let sessions: [UserSession]

    struct UserSession: Codable {
        let userId: String
        let accessToken: String
        let active: Bool
        let expiresAt: Int
        let refreshToken: String
    }
}

struct EditUser: Codable {
    let username: String
    let bio: String
    let venmoHandle: String
    let photoUrlBase64: String
}

struct BlockUser: Codable {
    let blocked: String
}

struct UnblockUser: Codable {
    let unblocked: String
}
