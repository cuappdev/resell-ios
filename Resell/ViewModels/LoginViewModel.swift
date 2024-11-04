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

    func googleSignIn(success: @escaping () -> Void ) {
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
            guard error == nil else { return }

            guard let email = result?.user.profile?.email else { return }

            guard email.contains("@cornell.edu") else {
                GIDSignIn.sharedInstance.signOut()
                self.didPresentError = true
                self.errorText = "Please sign in with a Cornell email"
                return
            }

            guard let id = result?.user.userID else { return }

            self.getUserSession(googleID: id)

            success()
        }
    }

    func restoreLogin() {
        Task {
            do {
                // Attempt to use the existing accessToken from the Keychain
                if let accessToken = UserSessionManager.shared.accessToken,
                   let userID = UserSessionManager.shared.userID {
                    // Verify that the accessToken is valid by attempting to get the user session
                    let userSession = try await NetworkManager.shared.getUserSession(id: userID)
                    UserSessionManager.shared.accessToken = userSession.sessions.first?.accessToken
                } else if let googleID = UserSessionManager.shared.googleID {
                    // If accessToken is not available, try to re-authenticate using googleID
//                    try await reauthenticateWithGoogleID(googleID: googleID)
                } else {
                    // If neither accessToken nor googleID is available, show an error
                    didPresentError = true
                    errorText = "No stored login information available. Please log in again."
                }
            } catch {
                didPresentError = true
                errorText = "Failed to restore login: \(error.localizedDescription)"
                NetworkManager.shared.logger.error("Error in LoginViewModel.restoreLogin: \(error.localizedDescription)")
            }
        }
    }

    private func getUserSession(googleID: String) {
        Task {
            do {
                let user = try await NetworkManager.shared.getUserByGoogleID(googleID: googleID).user
//                let userSession = try await NetworkManager.shared.getUserSession(id: user.id).sessions.first

//                UserSessionManager.shared.accessToken = userSession?.accessToken
                UserSessionManager.shared.googleID = googleID
                UserSessionManager.shared.userID = user.id
            } catch {
                NetworkManager.shared.logger.error("Error in LoginViewModel.getUserSession: \(error)")
            }
        }
    }
}

