//
//  SettingsView.swift
//  Resell
//
//  Created by Richie Sun on 9/23/24.
//

import SwiftUI

struct SettingsView: View {
    
    // MARK: - Properties
    
    @Environment(\.dismiss) var dismiss
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
            Icon(image: item.icon)
                .foregroundStyle(Constants.Colors.black)
                .padding(.trailing, 24)

            Text(item.title)
                .font(Constants.Fonts.body1)
                .foregroundStyle(Constants.Colors.black)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(Constants.Colors.black)
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
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(25)
    }
}

#Preview {
    SettingsView(isAccountSettings: false)
}
