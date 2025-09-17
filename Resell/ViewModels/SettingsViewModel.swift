//
//  SettingsViewModel.swift
//  Resell
//
//  Created by Richie Sun on 9/23/24.
//

import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {

    // MARK: - Properties

    @Published var confirmUsernameText: String = ""
    @Published var didShowDeleteAccountView: Bool = false
    @Published var didShowLogoutView: Bool = false
    @Published var didShowWebView: Bool = false

    var settings: [Settings] = [
        .accountSettings,
        .notifications,
        .sendFeedback,
        .blockedUsers,
        .eula,
        .logout
    ]

    var accountSettings: [Settings] = [
        .editProfile,
        .deleteAccount
    ]

    // MARK: - Functions

    func togglePopup(isPresenting: Bool) {
        withAnimation {
            didShowDeleteAccountView = isPresenting
        }
    }

    private func presentDeleteAccount() {
        didShowDeleteAccountView = true
    }

    private func presentEULA() {
        didShowWebView = true
    }

    private func presentLogout() {
        didShowLogoutView = true
    }

    func logout() {
        Task {
            do {
                let _ = try await NetworkManager.shared.logout()
                GoogleAuthManager.shared.signOut()
            } catch {
                NetworkManager.shared.logger.error("Error in SettingsViewModel.logout: \(error)")
            }
        }

    }

    func deleteAccount() {
        Task {
            do {
                if let userID = GoogleAuthManager.shared.user?.firebaseUid {
                    try await NetworkManager.shared.deleteAccount(userID: userID)
                } else {
                    GoogleAuthManager.shared.logger.error("Error in \(#file) \(#function): User not available.")
                }
            } catch {
                NetworkManager.shared.logger.error("Error in \(#file) \(#function): \(error)")
            }
        }
    }
}

enum Settings {
    case editProfile
    case deleteAccount
    case accountSettings
    case notifications
    case sendFeedback
    case blockedUsers
    case eula
    case logout
}
