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
    let posts: [String]?
    let feedbacks: [String]?
}

struct UserResponse: Codable {
    let user: User
}
