//
//  GoogleAuthManager.swift
//  Resell
//
//  Created by Richie Sun on 12/3/24.
//

import GoogleSignIn
import OAuth2
import os
import SwiftUI

class GoogleAuthManager {

    static let shared = GoogleAuthManager()

    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.cornellappdev.Resell", category: "GoogleAuthManager")

    private init() { }

    func getOAuthToken(completion: @escaping (String) -> Void) throws {
        // 1. Locate the service account JSON file
        guard let credentialsPath = Bundle.main.path(forResource: "resell-service", ofType: "json") else {
            logger.error("Error in GoogleAuthManager: Service account file not found.")
            return
        }

        // 2. Initialize the ServiceAccountTokenProvider with the credentials and scopes
        let scopes = [
            "https://www.googleapis.com/auth/cloud-platform",
            "https://www.googleapis.com/auth/firebase.messaging"
        ]

        guard let provider = ServiceAccountTokenProvider(credentialsURL: URL(fileURLWithPath: credentialsPath), scopes: scopes) else {
            logger.error("Error in GoogleAuthManager: Failed to initialize ServiceAccountTokenProvider.")
            return
        }

        // 3. Fetch the token synchronously
        try provider.withToken { token, error in
            if let error = error {
                self.logger.error("Error in GoogleAuthManager: Error fetching token: \(error)")
            }
            if let accessToken = token?.AccessToken  {
                completion(accessToken)
            }
        }
    }

    // MARK: - Service Account Structure
    struct ServiceAccount: Decodable {
        let type: String
        let project_id: String
        let private_key_id: String
        let private_key: String
        let client_email: String
        let client_id: String
        let auth_uri: String
        let token_uri: String
        let auth_provider_x509_cert_url: String
        let client_x509_cert_url: String
    }

    struct OAuthTokenResponse: Decodable {
        let access_token: String
        let token_type: String
        let expires_in: Int
    }

    func signIn() async -> GIDGoogleUser? {
        do {
            guard let presentingViewController = await (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return nil }

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)

            return result.user
        } catch {
            logger.error("Error in GoogleAuthManager: Error restoring Google Sign-In: \(error.localizedDescription)")
            return nil
        }
    }

    func restorePreviousSignIn() async throws -> GIDGoogleUser? {
        if let user = GIDSignIn.sharedInstance.currentUser {
            return user
        } else {
            do {
                let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()
                
                return user
            } catch {
                logger.error("Error in GoogleAuthManager: Error restoring Google Sign-In: \(error.localizedDescription)")
                return nil
            }
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
}

