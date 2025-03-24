//
//  User.swift
//  Resell
//
//  Created by Richie Sun on 11/2/24.
//

import Foundation
import FirebaseAuth
import GoogleSignIn

struct User: Codable {
    let firebaseUid: String
    let username: String
    let netid: String
    let givenName: String
    let familyName: String
    let admin: Bool
    let isActive: Bool
    let stars: String
    let numReviews: Int
    let photoUrl: URL
    let venmoHandle: String
    let email: String
    let googleId: String
    let bio: String
    let posts: [Post]
    let saved: [String]
    let feedbacks: [Feedback]
    let requests: [String]
    let blocking: [String]?
    let blockers: [String]?
    let reports: [String]?
    let reportedBy: [String]?

    enum CodingKeys: String, CodingKey {
        case firebaseUid
        case username
        case netid
        case givenName
        case familyName
        case admin
        case isActive
        case stars
        case numReviews
        case photoUrl
        case venmoHandle
        case email
        case googleId
        case bio
        case posts
        case saved
        case feedbacks
        case requests
        case blocking
        case blockers
        case reports
        case reportedBy
    }

    func toCreateUserBody(username: String, bio: String, venmoHandle: String, imageUrl: String, fcmToken: String) -> CreateUserBody {
        return CreateUserBody(
            username: username,
            netid: self.netid,
            givenName: self.givenName,
            familyName: self.familyName,
            photoUrl: imageUrl,
            venmoHandle: venmoHandle,
            email: self.email,
            googleId: self.googleId,
            bio: bio,
            fcmToken: fcmToken
        )
    }

    static func fromGUser(_ user: GIDGoogleUser, firebaseUserId: String) throws -> User {
        guard let defaultImageUrl = URL(string: "http://www.gravatar.com/avatar/?d=mp") else {
            // TODO: Throw better error
            throw URLError(.badServerResponse)
        }

        return User(
            firebaseUid: firebaseUserId,
            username: user.profile?.email ?? "",
            netid: String(user.profile?.email.split(separator: "@")[0] ?? ""),
            givenName: user.profile?.givenName ?? "",
            familyName: user.profile?.familyName ?? "",
            admin: false,
            isActive: true,
            stars: "0",
            numReviews: 0,
            photoUrl: user.profile?.imageURL(withDimension: 512) ?? defaultImageUrl,
            venmoHandle: "",
            email: user.profile?.email ?? "",
            googleId: user.userID ?? "",
            bio: "",
            posts: [],
            saved: [],
            feedbacks: [],
            requests: [],
            blocking: [],
            blockers: [],
            reports: [],
            reportedBy: []
        )
    }
}

struct UsersResponse: Codable {
    let users: [User]
}

struct UserResponse: Codable {
    let user: User
}

struct CreateUserBody: Codable {
    let username: String
    let netid: String
    let givenName: String
    let familyName: String
    let photoUrl: String
    let venmoHandle: String
    let email: String
    let googleId: String
    let bio: String
    let fcmToken: String
}

struct EditUserBody: Codable {
    let username: String
    let bio: String
    let venmoHandle: String
    let photoUrlBase64: String
}

struct BlockUserBody: Codable {
    let blocked: String
}

struct UnblockUserBody: Codable {
    let unblocked: String
}

struct LogoutResponse: Codable {
    let logoutSuccess: Bool
}

struct AuthorizeBody: Codable {
    let token: String?
}
