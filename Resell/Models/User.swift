//
//  User.swift
//  Resell
//
//  Created by Richie Sun on 11/2/24.
//

import Foundation
import FirebaseAuth
import GoogleSignIn

struct User: Codable, Equatable, Hashable {
    let firebaseUid: String
    let username: String
    let netid: String
    let givenName: String
    let familyName: String
    let admin: Bool
    let isActive: Bool
    let stars: String
    let numReviews: Int
    let following: [User]?
    let followers: [User]?
    let soldPosts: Int?
    let photoUrl: URL
    let venmoHandle: String?
    let email: String
    let googleId: String
    let bio: String
    let posts: [Post]?
    let saved: [Post]?
    let feedbacks: [Feedback]?
    let requests: [Request]?
    let blocking: [String]?
    let blockers: [String]?
    let reports: [Report]?
    let reportedBy: [String]?

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

        // Safely derive the netid from the email's local-part. The previous
        // implementation force-subscripted `[0]` on the result of `split`,
        // which traps with "Index out of range" when the email is empty
        // (`"".split(separator: "@") == []`). Use `.first` instead so an
        // empty/odd profile email simply produces an empty netid.
        let email = user.profile?.email ?? ""
        let netid = email.split(separator: "@").first.map(String.init) ?? ""

        return User(
            firebaseUid: firebaseUserId,
            username: user.profile?.email ?? "",
            netid: netid,
            givenName: user.profile?.givenName ?? "",
            familyName: user.profile?.familyName ?? "",
            admin: false,
            isActive: true,
            stars: "0.0",
            numReviews: 0,
            following: [],
            followers: [],
            soldPosts: 0,
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

    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.firebaseUid == rhs.firebaseUid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(firebaseUid)
    }
    
    func updatingProfile(newUsername: String, newBio: String, newVenmoHandle: String, newPhotoUrl: URL) -> User {
        return User(
            firebaseUid: self.firebaseUid,
            username: newUsername,
            netid: self.netid,
            givenName: self.givenName,
            familyName: self.familyName,
            admin: self.admin,
            isActive: self.isActive,
            stars: self.stars,
            numReviews: self.numReviews,
            following: self.following,
            followers: self.followers,
            soldPosts: self.soldPosts,
            photoUrl: newPhotoUrl,
            venmoHandle: newVenmoHandle,
            email: self.email,
            googleId: self.googleId,
            bio: newBio,
            posts: self.posts,
            saved: self.saved,
            feedbacks: self.feedbacks,
            requests: self.requests,
            blocking: self.blocking,
            blockers: self.blockers,
            reports: self.reports,
            reportedBy: self.reportedBy
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

struct FollowUserBody: Codable {
    let userId: String
}

struct UnfollowUserBody: Codable {
    let userId: String
}
