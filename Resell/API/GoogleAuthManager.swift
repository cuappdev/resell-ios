//
//  GoogleAuthManager.swift
//  Resell
//
//  Created by Richie Sun on 12/3/24.
//

import FirebaseAuth
import GoogleSignIn
import OAuth2
import os
import SwiftUI

class GoogleAuthManager {

    // MARK: - Singleton Instance
    
    static let shared = GoogleAuthManager()

    // MARK: - Error Logger for Google Auth

    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.cornellappdev.Resell", category: #file)

    // MARK: - Properties

    var accessToken: String? {
        didSet {
            if let token = accessToken {
                KeychainManager.shared.save(token, forKey: "accessToken")
            } else {
                KeychainManager.shared.delete(forKey: "accessToken")
            }
        }
    }

    var user: User?

    // MARK: - Init

    private init() { }

    // MARK: - Functions

    func signIn() async throws {
        guard let presentingViewController = await (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return }

        // Wait for result of sign-in
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        try await getCredentialsFromGoogleUser(user: gidSignInResult.user)
        try await authorizeUser()
    }

    /// Try to refresh the access token of the current user if it exists, or the restored user.
    /// If this function throws a full logout is needed.
    func refreshSignInIfNeeded() async throws {
        // Restore or verify sign-in
        if GIDSignIn.sharedInstance.currentUser == nil {
            try await GIDSignIn.sharedInstance.restorePreviousSignIn()
        }

        // Get current user or throw
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleAuthError.noUserSignedIn
        }

        // Refresh tokens
        try await currentUser.refreshTokensIfNeeded()

        try await getCredentialsFromGoogleUser(user: currentUser)
        try await authorizeUser()
    }

    func getCredentialsFromGoogleUser(user: GIDGoogleUser) async throws {
        guard let idToken = user.idToken?.tokenString else {
            // TODO: Throw a better error
            throw GoogleAuthError.noUserSignedIn
        }

        // Convert to firebase credential
        let credentials = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
        let authResult = try await Auth.auth().signIn(with: credentials)

        self.user = try User.fromGUser(user, firebaseUserId: authResult.user.uid)

        // Update accessToken and authorize the user with backend
        self.accessToken = try await Auth.auth().currentUser?.getIDToken(forcingRefresh: true)
        print("accessToken:", self.accessToken ?? "")
    }

    func signOut() {
        // TODO: Logout networking endpoint with FCM
        GIDSignIn.sharedInstance.signOut()
        accessToken = nil
        user = nil
    }

    private func authorizeUser() async throws {
        // Send FCM token to backend
        guard let fcmToken = await FirebaseNotificationService.shared.getFCMRegToken() else {
            throw GoogleAuthError.noFCMToken
        }

        print("fcmToken:", fcmToken)

        let body = AuthorizeBody(token: fcmToken)
        self.user = try await NetworkManager.shared.authorize(authorizeBody: body)
    }
}

enum GoogleAuthError: Error, LocalizedError {
    case noUserSignedIn
    case noFCMToken

    var errorDescription: String? {
        switch self {
        case .noUserSignedIn:
            return "No user is currently signed in."
        case .noFCMToken:
            return "Firebase Cloud Messaging token is missing. Please check configuration."
        }
    }

}
