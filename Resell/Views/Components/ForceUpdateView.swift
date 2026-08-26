//
//  ForceUpdateView.swift
//  Resell
//
//  Created by Andrew Gao on 4/28/26.
//

import SwiftUI

struct ForceUpdateView: View {
    @Environment(\.openURL) private var openURL

    let installedVersion: String
    let requiredVersion: String
    let appStoreId: String
    let onTryAgain: () -> Void

    private var canOpenStore: Bool {
        !appStoreId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 10) {
                Text("Update Required")
                    .font(Constants.Fonts.h2)
                    .foregroundStyle(Constants.Colors.black)

                Text("To keep using Resell, please update to the latest version.")
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .multilineTextAlignment(.center)

                if !installedVersion.isEmpty || !requiredVersion.isEmpty {
                    Text("Installed \(installedVersion.isEmpty ? "—" : installedVersion) • Required \(requiredVersion.isEmpty ? "—" : requiredVersion)")
                        .font(.caption)
                        .foregroundStyle(Constants.Colors.secondaryGray)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Button {
                    guard canOpenStore else { return }
                    if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appStoreId)") {
                        openURL(url)
                    }
                } label: {
                    Text("Update")
                        .font(Constants.Fonts.title2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(Constants.Colors.white)
                        .background(Constants.Colors.resellPurple)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!canOpenStore)

                Button {
                    onTryAgain()
                } label: {
                    Text("Try again")
                        .font(Constants.Fonts.title2)
                        .foregroundStyle(Constants.Colors.resellPurple)
                }

                if !canOpenStore {
                    Text("App Store link not configured yet.")
                        .font(.caption)
                        .foregroundStyle(Constants.Colors.secondaryGray)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.Colors.white)
    }
}

