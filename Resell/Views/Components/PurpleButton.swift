//
//  ResellPurpleButton.swift
//  Resell
//
//  Created by Richie Sun on 9/9/24.
//

import SwiftUI

/// Reusable purple button
struct PurpleButton: View {

    // MARK: - Properties

    var isActive: Bool = false

    let text: String
    var horizontalPadding: CGFloat = 48
    let action: () -> Void

    // MARK: - UI

    var body: some View {
        VStack {
            Button(action: { if isActive { action() } }, label: {
                buttonContent
                    .opacity(isActive ? 1.0 : 0.4)
            })
        }
    }

    private var buttonContent: some View {
        Text(text)
            .font(Constants.Fonts.title1)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 14)
            .background(Constants.Colors.resellPurple)
            .foregroundStyle(Constants.Colors.white)
            .clipShape(.capsule)
    }
}

/// Reusable purple button that works as a NavigationLink
struct NavigationPurpleButton<Destination: View>: View {

    // MARK: - Properties

    var isActive: Bool = false
    let text: String
    var horizontalPadding: CGFloat = 48
    let destination: Destination

    // MARK: - UI

    var body: some View {
        NavigationLink(destination: destination) {
            buttonContent
                .opacity(isActive ? 1.0 : 0.4)
        }
        .disabled(!isActive)
    }

    private var buttonContent: some View {
        Text(text)
            .font(Constants.Fonts.title1)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 14)
            .background(Constants.Colors.resellPurple)
            .foregroundColor(Constants.Colors.white)
            .clipShape(Capsule())
    }
}

