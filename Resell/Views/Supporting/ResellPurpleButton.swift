//
//  ResellPurpleButton.swift
//  Resell
//
//  Created by Richie Sun on 9/9/24.
//

import SwiftUI

struct ResellPurpleButton: View {

    // MARK: - Properties

    let text: String
    let horizontalPadding: CGFloat?
    let action: () -> Void

    // MARK: - Init

    init(text: String, horizontalPadding: CGFloat? = 48, action: @escaping () -> Void) {
        self.text = text
        self.horizontalPadding = horizontalPadding
        self.action = action
    }

    // MARK: - UI

    var body: some View {
        VStack {
            Button(action: action, label: {
                Text(text)
                    .font(Constants.Fonts.title1)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 14)
                    .background(Constants.Colors.resellPurple)
                    .foregroundStyle(Constants.Colors.white)
                    .clipShape(.capsule)
            })
        }
    }
}
