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
        .blockerUsers,
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
}

enum Settings {
    case editProfile
    case deleteAccount
    case accountSettings
    case notifications
    case sendFeedback
    case blockerUsers
    case eula
    case logout
}
