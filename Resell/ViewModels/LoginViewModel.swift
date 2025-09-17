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

    @Published var isLoading = false
    @Published var didPresentError = false
    var errorText: String = ""

    // MARK: - Functions

    func googleSignIn() async -> LoginResponse {
        do {
            try await GoogleAuthManager.shared.signIn()
            return .success
        } catch {
            switch error {
            case let errorResponse as ErrorResponse:
                if errorResponse == ErrorResponse.accountCreationNeeded {
                    return .accountCreationNeeded
                } else {
                    errorText = "\(errorResponse.error)"
                }
            default:
                errorText = "Any unknown error occured."
            }

            GoogleAuthManager.shared.logger.log("Error in \(#file) \(#function): \(error)")

            await MainActor.run {
                didPresentError = true
            }

            return .failed
        }
    }

    enum LoginResponse {
        case failed
        case accountCreationNeeded
        case success
    }

}

