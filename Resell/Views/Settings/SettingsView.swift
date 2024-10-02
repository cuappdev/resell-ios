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
    @StateObject private var viewModel = SettingsViewModel()
    var isAccountSettings: Bool = false

    // MARK: - UI
    
    var body: some View {
        NavigationStack {
            VStack {
                ForEach(isAccountSettings ? viewModel.accountSettings : viewModel.settings, id: \.id) { setting in
                    NavigationLink(destination: setting.destination) {
                        settingsRow(item: setting)
                    }
                }
            }
            .padding(.top, 24)

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton(dismiss: self.dismiss)
            }
            
            ToolbarItem(placement: .principal) {
                Text(isAccountSettings ? "Account Settings" : "Settings")
                    .font(Constants.Fonts.h3)
            }
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

}
