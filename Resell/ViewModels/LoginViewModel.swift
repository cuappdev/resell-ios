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

    private func getUserSession(googleID: String) {
        Task {
            do {
                let user = try await NetworkManager.shared.getUserByGoogleID(googleID: googleID).user
                let userSession = try await NetworkManager.shared.getUserSession(id: user.id).sessions.first

                UserSessionManager.shared.accessToken = userSession?.accessToken
                UserSessionManager.shared.googleID = googleID
                UserSessionManager.shared.userID = user.id
            } catch {
                NetworkManager.shared.logger.error("Error in LoginViewModel.getUserSession: \(error)")
            }
        }
    }
}

