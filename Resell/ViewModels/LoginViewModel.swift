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
    @Published var errorText: String = ""

    // MARK: - Functions

    func googleSignIn(success: @escaping () -> Void, failure: @escaping (_ netid: String, _ givenName: String, _ familyName: String, _ email: String, _ googleId: String) -> Void) {
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error  in
            guard error == nil else { return }
            guard let self else { return }

            guard let email = result?.user.profile?.email else { return }

            guard email.contains("@cornell.edu") else {
                GIDSignIn.sharedInstance.signOut()
                self.didPresentError = true
                self.errorText = "Please sign in with a Cornell email"
                return
            }

            guard let id = result?.user.userID else { return }

            Task {
                do {
                    let user = try await NetworkManager.shared.getUserByGoogleID(googleID: id).user
                    let userSession = try await NetworkManager.shared.getUserSession(id: user.id).sessions.first

                    UserSessionManager.shared.accessToken = userSession?.accessToken
                    UserSessionManager.shared.googleID = id
                    UserSessionManager.shared.userID = user.id
                    UserSessionManager.shared.email = user.email
                    UserSessionManager.shared.profileURL = user.photoUrl
                    UserSessionManager.shared.name = "\(user.givenName) \(user.familyName)"

                    success()
                } catch {
                    NetworkManager.shared.logger.error("Error in LoginViewModel.getUserSession: \(error)")

                    guard let givenName = result?.user.profile?.givenName,
                          let familyName = result?.user.profile?.familyName else { return }

                    // User id does not exist, take to onboarding
                    failure(self.getNetID(email: email), givenName, familyName, email, id)
                }
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

