//
//  SettingsView.swift
//  Resell
//
//  Created by Richie Sun on 9/23/24.
//

import SwiftUI

struct SettingsView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    @EnvironmentObject var mainViewModel: MainViewModel
    @StateObject private var viewModel = SettingsViewModel()

    let isAccountSettings: Bool

    // MARK: - Init

    init(isAccountSettings: Bool) {
        self.isAccountSettings = isAccountSettings
    }

    // MARK: - UI

    var body: some View {
        VStack {
            ForEach(isAccountSettings ? viewModel.accountSettings : viewModel.settings, id: \.self) { setting in
                switch setting {
                case .accountSettings:
                    settingsRow(title: "Account Settings", icon: "user") {
                        router.push(.settings(true))
                    }
                case .editProfile:
                    settingsRow(title: "Edit Profile", icon: "edit") {
                        router.push(.editProfile)
                    }
                case .deleteAccount:
                    settingsRow(isRed: true, title: "Delete Account", icon: "") {
                        withAnimation { viewModel.didShowDeleteAccountView = true }
                    }
                // MARK: Omit notifications for release...
//                case .notifications:
//                    settingsRow(title: "Notifications", icon: "notifications") {
//                        router.push(.notifications)
//                    }
                case .sendFeedback:
                    settingsRow(title: "Send Feedback", icon: "feedback") {
                        router.push(.feedback)
                    }
                case .blockedUsers:
                    settingsRow(title: "Blocked Users", icon: "slash") {
                        router.push(.blockedUsers)
                    }
                case .eula:
                    settingsRow(title: "Term and Conditions", icon: "terms") {
                        viewModel.didShowWebView = true
                    }
                case .logout:
                    settingsRow(title: "Log Out", icon: "logout") {
                        viewModel.didShowLogoutView = true
                    }
                }

            }

            Spacer()
        }
        .padding(.top, 24)
        .background(Constants.Colors.white)
        .sheet(isPresented: $viewModel.didShowWebView) {
            WebView(url: URL(string: "https://www.cornellappdev.com/license/resell")!)
                .edgesIgnoringSafeArea(.all)
        }
        .sheet(isPresented: $viewModel.didShowLogoutView) {
            logoutView
        }
        .popupModal(isPresented: $viewModel.didShowDeleteAccountView) {
            popupModalContent
                .padding(Constants.Spacing.horizontalPadding)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(isAccountSettings ? "Account Settings" : "Settings")
                    .font(Constants.Fonts.h3)
                    .foregroundStyle(Constants.Colors.black)
            }
        }
    }

    private func settingsRow(isRed: Bool = false, title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action, label: {
            HStack(alignment: .top, spacing: 0) {
                if !isRed {
                    Icon(image: icon)
                        .foregroundStyle(Constants.Colors.black)
                        .padding(.trailing, 24)
                }

                Text(title)
                    .font(Constants.Fonts.body1)
                    .foregroundStyle(isRed ? Constants.Colors.errorRed : Constants.Colors.black)

                Spacer()

                if !isRed {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Constants.Colors.black)
                }
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
            .padding(.vertical, 18.5)
            .background(Color.white)
        })
    }

    private var logoutView: some View {
        VStack(spacing: 24) {
            Text("Log out of Resell?")
                .font(Constants.Fonts.h3)
                .foregroundStyle(Constants.Colors.black)
                .multilineTextAlignment(.center)
                .frame(width: 190)
                .padding(.top, 48)

            PurpleButton(isAlert: true, text: "Logout", horizontalPadding: 70) {
                GoogleAuthManager.shared.signOut()
                viewModel.logout()
                router.popToRoot()
                mainViewModel.selection = 0
                mainViewModel.hidesSignInButton = false
                mainViewModel.userDidLogin = false
            }

            Button{
                withAnimation {
                    viewModel.didShowLogoutView = false
                }
            } label: {
                Text("Cancel")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.black)
            }
        }
        .background(Constants.Colors.white)
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(25)
        .presentationBackground(Constants.Colors.white)
    }

    private var popupModalContent: some View {
        VStack(spacing: 16) {
            Text("Delete Account")
                .font(Constants.Fonts.h3)
                .foregroundStyle(Constants.Colors.black)

            Text("Once deleted, your account cannot be recovered. Enter your username to proceed with deletion.")
                .font(Constants.Fonts.body2)
                .foregroundStyle(Constants.Colors.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            TextField("", text: $viewModel.confirmUsernameText)
                .font(Constants.Fonts.body2)
                .foregroundStyle(Constants.Colors.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Constants.Colors.secondaryGray, lineWidth: 0.5)
                }

            Button {
                viewModel.deleteAccount()
                mainViewModel.selection = 0
                mainViewModel.userDidLogin = false
            } label: {
                Text("Delete Account")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.white)
                    .padding(.horizontal, 70)
                    .padding(.vertical, 14)
                    .background(Constants.Colors.errorRed)
                    .clipShape(.capsule)
            }


            Button {
                viewModel.togglePopup(isPresenting: false)
            } label: {
                Text("Cancel")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.secondaryGray)
            }
        }
        .frame(width: 300)
    }
}

#Preview {
    SettingsView(isAccountSettings: false)
}
