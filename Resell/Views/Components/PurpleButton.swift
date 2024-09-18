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
                Text(text)
                    .font(Constants.Fonts.title1)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 14)
                    .background(isActive ? Constants.Colors.resellPurple : Constants.Colors.resellPurple.opacity(0.4))
                    .foregroundStyle(Constants.Colors.white)
                    .clipShape(.capsule)
            })
        }
    }
}
