//
//  NotificationsSettingsView.swift
//  Resell
//
//  Created by Richie Sun on 10/5/24.
//

import SwiftUI

struct NotificationsSettingsView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    @EnvironmentObject var mainViewModel: MainViewModel

    private var allNotificationsEnabled: Bool {
        !mainViewModel.chatNotificationsEnabled && !mainViewModel.newListingsEnabled
    }

    // MARK: - UI

    var body: some View {
        VStack(spacing: 40) {
            notificationSetting(name: "Pause All Notifications", isOn: Binding<Bool>(
                get: { allNotificationsEnabled },
                set: { paused in
                    mainViewModel.toggleAllNotifications(paused: paused)
                }
            ))

            notificationSetting(name: "Chat Notifications", isOn: $mainViewModel.chatNotificationsEnabled)

            notificationSetting(name: "New Listings", isOn: $mainViewModel.newListingsEnabled)

            Spacer()
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .padding(.top, 40)
        .background(Constants.Colors.white)
        .toolbar {

            ToolbarItem(placement: .principal) {
                Text("Notification Preferences")
                    .font(Constants.Fonts.h3)
            }
        }
    }

    // MARK: - Functions

    private func notificationSetting(name: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(name)
                .font(Constants.Fonts.body1)
                .foregroundStyle(Constants.Colors.black)
        }
        .tint(Constants.Colors.resellPurple)
    }

}
