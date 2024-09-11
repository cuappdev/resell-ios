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

    func googleSignIn() {
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
            guard error == nil else { return }

            guard let email = result?.user.profile?.email else { return }

            guard email.contains("@cornell.edu") else {
                GIDSignIn.sharedInstance.signOut()
                print("User is not a cornell student")
                return
            }
        }
    }
}

