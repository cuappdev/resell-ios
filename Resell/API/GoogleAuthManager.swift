//
//  GoogleAuthManager.swift
//  Resell
//
//  Created by Richie Sun on 12/3/24.
//

import GoogleSignIn
import OAuth2
import SwiftJWT
import SwiftUI

class GoogleAuthManager {

    static let shared = GoogleAuthManager()

    private let credentials = "resell-service.json"
    private let token = "resell-service.json"

    private let scopes = [
        "profile",
        "https://www.googleapis.com/auth/firebase.messaging",
        "https://www.googleapis.com/auth/cloud-platform"
    ]

    private init() { }

    func getOAuthToken(completion: @escaping (String) -> Void) {
        // 1. Locate the service account JSON file
        guard let credentialsPath = Bundle.main.path(forResource: "resell-service", ofType: "json") else {
            print("Service account file not found.")
            return
        }

        // 2. Initialize the ServiceAccountTokenProvider with the credentials and scopes
        let scopes = [
            "https://www.googleapis.com/auth/cloud-platform",
            "https://www.googleapis.com/auth/firebase.messaging"
        ]
        
        guard let provider = ServiceAccountTokenProvider(credentialsURL: URL(fileURLWithPath: credentialsPath), scopes: scopes) else {
            print("Failed to initialize ServiceAccountTokenProvider.")
            return
        }

        // 3. Fetch the token synchronously
        do {
            try provider.withToken { token, error in
                if let error = error {
                    print("Error fetching token: \(error)")
                }
                if let accessToken = token?.AccessToken  {
                    completion(accessToken)
                }
            }
        } catch {
            print("Failed to fetch token: \(error)")
            return
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

    struct GoogleJWTClaims: Claims {
        let iss: String
        let scope: String
        let aud: String
        let exp: Date
        let iat: Date
    }

    struct OAuthTokenResponse: Decodable {
        let access_token: String
        let token_type: String
        let expires_in: Int
    }

    func getAccessToken() async throws -> String {
        // 1. Load the service account JSON file
        guard let credentialsPath = Bundle.main.path(forResource: "resell-service", ofType: "json"),
              let credentialsData = try? Data(contentsOf: URL(fileURLWithPath: credentialsPath)) else {
            throw NSError(domain: "OAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service account file not found"])
        }
        let serviceAccount = try JSONDecoder().decode(ServiceAccount.self, from: credentialsData)

        // 2. Create JWT claims
        let iat = Date()
        let exp = iat.addingTimeInterval(3600) // Token valid for 1 hour
        let claims = GoogleJWTClaims(
            iss: serviceAccount.client_email,
            scope: "https://www.googleapis.com/auth/cloud-platform",
            aud: serviceAccount.token_uri,
            exp: exp,
            iat: iat
        )

        // 3. Create and sign the JWT
        var jwt = JWT(header: Header(kid: serviceAccount.private_key_id), claims: claims)
        let privateKey = serviceAccount.private_key.replacingOccurrences(of: "\\n", with: "\n")
        guard let privateKeyData = privateKey.data(using: .utf8) else {
            throw NSError(domain: "JWTError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert private key to Data"])
        }
        let signer = JWTSigner.rs256(privateKey: privateKeyData)
        let jwtString = try jwt.sign(using: signer)

        // 4. Exchange JWT for an access token
        var request = URLRequest(url: URL(string: serviceAccount.token_uri)!)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let requestBody = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwtString)"
        request.httpBody = requestBody.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            throw NSError(domain: "OAuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch access token. Response: \(responseBody)"])
        }

        // 5. Parse the access token from the response
        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        return tokenResponse.access_token
    }

    func signIn() async -> GIDGoogleUser? {
        do {
            guard let presentingViewController = await (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return nil }

            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)

            let accessToken = result.user.accessToken.tokenString
                print("Access Token: \(accessToken)")

            return result.user
        } catch {
            print("Error restoring Google Sign-In: \(error.localizedDescription)")
            return nil
        }
    }

    func restorePreviousSignIn() async throws -> GIDGoogleUser? {
        if let user = GIDSignIn.sharedInstance.currentUser {
            return user
        } else {
            do {
                let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()

                let accessToken = user.accessToken.tokenString
                    print("Access Token: \(accessToken)")
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

