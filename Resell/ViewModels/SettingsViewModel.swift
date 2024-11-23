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
            } catch {
                NetworkManager.shared.logger.error("Error in SettingsViewModel.logout: \(error)")
            }
        }

    }

    func deleteAccount() {
        Task {
            do {
                if let userID = UserSessionManager.shared.userID {
                    try await NetworkManager.shared.deleteAccount(userID: userID)
                } else {
                    UserSessionManager.shared.logger.error("Error in SettingsViewModel.deleteAccount: userID not found")
                }
            } catch {
                NetworkManager.shared.logger.error("Error in SettingsViewModel.deleteAccount: \(error)")
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
