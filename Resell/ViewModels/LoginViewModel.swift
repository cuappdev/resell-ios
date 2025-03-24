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
    @Published var isLoading: Bool = false
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
                errorText = "Error: \(error)"
            }

            GoogleAuthManager.shared.logger.log("Error in \(#file) \(#function): \(error)")

            await MainActor.run {
                didPresentError = true
            }

            return .failed
        }

        if GoogleAuthManager.shared.user == nil {
            await MainActor.run {
                isLoading = false
                didPresentError = true
                return LoginResponse.failed
            }
        }

        return .success
    }

    enum LoginResponse {
        case failed
        case accountCreationNeeded
        case success
    }

}

