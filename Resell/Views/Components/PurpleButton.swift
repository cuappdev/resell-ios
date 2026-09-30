//
//  ResellPurpleButton.swift
//  Resell
//
//  Created by Richie Sun on 9/9/24.
//

import SwiftUI

/// Reusable primary CTA rendered as prominent Liquid Glass tinted with the Resell brand color
struct PurpleButton: View {

    // MARK: - Properties

    var isLoading: Bool = false
    var isActive: Bool = true
    var isAlert: Bool = false
    let text: String
    var horizontalPadding: CGFloat = 48
    let action: () -> Void

    // MARK: - UI

    var body: some View {
        Button(action: { if isActive { action() } }, label: {
            buttonContent
        })
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .tint(isAlert ? Constants.Colors.errorRed : Constants.Colors.resellPurple)
        .opacity(isActive ? 1.0 : 0.4)
        .disabled(!isActive)
    }

    private var buttonContent: some View {
        HStack(spacing: 12) {
            if isLoading {
                CustomProgressView(color: Constants.Colors.white, size: 20, lineWidth: 4)
            }

            Text(text)
                .font(Constants.Fonts.title1)
                .foregroundStyle(Constants.Colors.white)
        }
        .padding(.horizontal, max(horizontalPadding - 20, 0))
        .padding(.vertical, 6)
    }

}

/// Reusable primary CTA that works as a NavigationLink
struct NavigationPurpleButton<Destination: View>: View {

    // MARK: - Properties

    var isActive: Bool = true
    var isAlert: Bool = false
    let text: String
    var horizontalPadding: CGFloat = 48
    let destination: Destination

    // MARK: - UI

    var body: some View {
        NavigationLink(destination: destination) {
            Text(text)
                .font(Constants.Fonts.title1)
                .foregroundStyle(Constants.Colors.white)
                .padding(.horizontal, max(horizontalPadding - 20, 0))
                .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .tint(isAlert ? Constants.Colors.errorRed : Constants.Colors.resellPurple)
        .opacity(isActive ? 1.0 : 0.4)
        .disabled(!isActive)
    }
}
