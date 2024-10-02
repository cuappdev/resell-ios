//
//  SettingsViewModel.swift
//  Resell
//
//  Created by Richie Sun on 9/23/24.
//

import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {

    // TODO: Change when implementing new screens
    @Published var settings: [SettingItem] = [
        SettingItem(id: 0, icon: "user", title: "Account Settings", destination: AnyView(SettingsView(isAccountSettings: true))),
        SettingItem(id: 1, icon: "notifications", title: "Notifications", destination: AnyView(Text("Placeholder"))),
        SettingItem(id: 2, icon: "feedback", title: "Send Feedback", destination: AnyView(Text("Placeholder"))),
        SettingItem(id: 3, icon: "slash", title: "Blocked Users", destination: AnyView(Text("Placeholder"))),
        SettingItem(id: 4, icon: "terms", title: "Terms and Conditions", destination: AnyView(WebView(url: URL(string: "https://www.cornellappdev.com/license/resell")!))),
        SettingItem(id: 5, icon: "logout", title: "Log Out", destination: AnyView(Text("Placeholder"))),
    ]

    @Published var accountSettings: [SettingItem] = [
        SettingItem(id: 5, icon: "edit", title: "Edit Profile", destination: AnyView(Text("Placeholder"))),
        SettingItem(id: 5, icon: "logout", title: "Log Out", destination: AnyView(Text("Placeholder"))),

    ]

}

struct SettingItem: Identifiable {
    let id: Int
    let icon: String
    let title: String
    let destination: AnyView
    var isAlert = false
}
