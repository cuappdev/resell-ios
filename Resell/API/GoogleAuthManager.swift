//
//  GoogleAuthManager.swift
//  Resell
//
//  Created by Richie Sun on 12/3/24.
//

import GoogleSignIn

class GoogleAuthManager {
    static let shared = GoogleAuthManager()

    private init() {}

    func getOAuthToken() async throws -> String? {
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
            throw NSError(domain: "GoogleAuthManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not signed in."])
        }

        let token = try await currentUser.refreshTokensIfNeeded().accessToken
        return token.tokenString
    }

    func restorePreviousSignIn() async throws -> GIDGoogleUser? {
        if let user = GIDSignIn.sharedInstance.currentUser {
            return user
        } else {
            do {
                let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
                return user
            } catch {
                print("Error restoring Google Sign-In: \(error.localizedDescription)")
                return nil
            }
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
}

