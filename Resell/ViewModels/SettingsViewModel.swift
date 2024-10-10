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
    @Published var settings: [SettingItem] = []

    // MARK: - Functions

    func setSettingsOptions(isAccountSettings: Bool) {
        if isAccountSettings {
            self.settings = [
                SettingItem(id: 1, icon: "edit", title: "Edit Profile", destination: AnyView(Text("Placeholder"))),
                SettingItem(id: 2, icon: "logout", title: "Delete Account", isRed: true, hasDestination: false, action: { self.togglePopup(isPresenting: true) }),
            ]
        } else {
            self.settings = [
                SettingItem(id: 0, icon: "user", title: "Account Settings", destination: AnyView(SettingsView(isAccountSettings: true))),
                SettingItem(id: 1, icon: "notifications", title: "Notifications", destination: AnyView(NotificationsSettingsView())),
                SettingItem(id: 2, icon: "feedback", title: "Send Feedback", destination: AnyView(SendFeedbackView())),
                SettingItem(id: 3, icon: "slash", title: "Blocked Users", destination: AnyView(BlockerUsersView())),
                SettingItem(id: 4, icon: "terms", title: "Terms and Conditions", hasDestination: false, action: presentEULA),
                SettingItem(id: 5, icon: "logout", title: "Log Out", hasDestination: false, action: presentLogout),
            ]
        }
    }

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

struct SettingItem: Identifiable {
    let id: Int
    let icon: String
    let title: String
    var isRed = false
    var hasDestination = true
    var destination: AnyView = AnyView(Text("placeholder"))
    var action: (() -> Void)?
}
