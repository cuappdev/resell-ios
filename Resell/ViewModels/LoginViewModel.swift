//
//  LoginViewModel.swift
//  Resell
//
//  Created by Richie Sun on 9/9/24.
//

import GoogleSignIn
import SwiftUI

@MainActor
class LoginViewModel: ObservableObject {

    // MARK: - Properties

    @Published var didPresentError: Bool = false
    var errorText: String = "Please sign in with a Cornell email"

    // MARK: - Functions

    func googleSignIn(success: @escaping () -> Void, failure: @escaping (_ netid: String, _ givenName: String, _ familyName: String, _ email: String, _ googleId: String) -> Void) {

        Task {
            guard let user = await GoogleAuthManager.shared.signIn(),
                  let id = user.userID else { return }

            guard let email = user.profile?.email else { return }

            guard email.contains("@cornell.edu") else {
                GIDSignIn.sharedInstance.signOut()
                didPresentError = true
                return
            }

            do {
                let user = try await NetworkManager.shared.getUserByGoogleID(googleID: id).user
                var userSession = try await NetworkManager.shared.getUserSession(id: user.id).sessions.first

                if !(userSession?.active ?? false) {
                    userSession = try await NetworkManager.shared.refreshToken()
                }

                UserSessionManager.shared.accessToken = userSession?.accessToken
                UserSessionManager.shared.refreshToken = userSession?.refreshToken
                UserSessionManager.shared.googleID = id
                UserSessionManager.shared.userID = user.id
                UserSessionManager.shared.email = user.email
                UserSessionManager.shared.profileURL = user.photoUrl
                UserSessionManager.shared.name = "\(user.givenName) \(user.familyName)"

                success()
            } catch {
                NetworkManager.shared.logger.error("Error in LoginViewModel.getUserSession: \(error)")

                guard let givenName = user.profile?.givenName,
                      let familyName = user.profile?.familyName else { return }

                // User id does not exist, take to onboarding
                failure(self.getNetID(email: email), givenName, familyName, email, id)
            }
        }
    }

    private func getNetID(email: String?) -> String {
        if let atIndex = email?.firstIndex(of: "@"),
           let username = email?[..<atIndex] {
            return String(username)
        } else {
            return ""
        }
    }
}

