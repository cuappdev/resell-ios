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
                    handleNotificationToggle(chatNotificationsDisabled: !mainViewModel.chatNotificationsEnabled)
                }
            ))

            notificationSetting(name: "Chat Notifications", isOn: Binding<Bool>(
                get: { mainViewModel.chatNotificationsEnabled },
                set: { enabled in
                    mainViewModel.chatNotificationsEnabled = enabled
                    handleNotificationToggle(chatNotificationsDisabled: !enabled)
                }
            ))

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
                    .foregroundStyle(Constants.Colors.black)
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

    /// Handles toggling notifications and updates Firestore as needed
    private func handleNotificationToggle(chatNotificationsDisabled: Bool) {
        guard let userEmail = UserSessionManager.shared.email else {
            FirestoreManager.shared.logger.error("User email not found while updating notification settings.")
            return
        }

        Task {
            do {
                try await FirestoreManager.shared.saveNotificationsEnabled(userEmail: userEmail, notificationsEnabled: !chatNotificationsDisabled)
                FirestoreManager.shared.logger.log("Notifications updated for \(userEmail): \(!chatNotificationsDisabled).")
            } catch {
                FirestoreManager.shared.logger.error("Failed to update notifications for \(userEmail): \(error.localizedDescription)")
            }
        }
    }
}
