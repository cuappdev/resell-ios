//
//  SettingsView.swift
//  Resell
//
//  Created by Richie Sun on 9/23/24.
//

import SwiftUI

struct SettingsView: View {
    
    // MARK: - Properties

    @EnvironmentObject var mainViewModel: MainViewModel
    @StateObject private var viewModel = SettingsViewModel()

    let isAccountSettings: Bool

    // MARK: - Init

    init(isAccountSettings: Bool) {
        self.isAccountSettings = isAccountSettings
    }

    // MARK: - UI
    
    var body: some View {
        NavigationStack {
            VStack {
                ForEach(viewModel.settings, id: \.id) { setting in
                    if setting.hasDestination {
                        NavigationLink(destination: setting.destination) {
                            settingsRow(item: setting)
                        }
                    } else {
                        if let action = setting.action {
                            Button(action: action, label: {
                                settingsRow(item: setting)
                            })
                        }
                    }
                }
            }
            .padding(.top, 24)
            .background(Constants.Colors.white)

            Spacer()
        }
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
            }
        }
        .onAppear {
            viewModel.setSettingsOptions(isAccountSettings: isAccountSettings)
        }
    }

    private func settingsRow(item: SettingItem) -> some View {
        HStack(alignment: .top, spacing: 0) {
            if !item.isRed {
                Icon(image: item.icon)
                    .foregroundStyle(Constants.Colors.black)
                    .padding(.trailing, 24)
            }

            Text(item.title)
                .font(Constants.Fonts.body1)
                .foregroundStyle(item.isRed ? Constants.Colors.errorRed : Constants.Colors.black)

            Spacer()
            
            if !item.isRed {
                Image(systemName: "chevron.right")
                    .foregroundColor(Constants.Colors.black)
            }
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .padding(.vertical, 18.5)
        .background(Color.white)
    }
    
    private var logoutView: some View {
        VStack(spacing: 24) {
            Text("Log out of Resell?")
                .font(Constants.Fonts.h3)
                .multilineTextAlignment(.center)
                .frame(width: 190)
                .padding(.top, 48)

            PurpleButton(isAlert: true, text: "Logout", horizontalPadding: 70) {
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
    }

    private var popupModalContent: some View {
        VStack(spacing: 16) {
            Text("Delete Account")
                .font(Constants.Fonts.h3)

            Text("Once deleted, your account cannot be recovered. Enter your username to proceed with deletion.")
                .font(Constants.Fonts.body2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            TextField("", text: $viewModel.confirmUsernameText)
                .font(Constants.Fonts.body2)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Constants.Colors.secondaryGray, lineWidth: 0.5)
                }

            Button {
                // TODO: Delete Account Backend Call
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
