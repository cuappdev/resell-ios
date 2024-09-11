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
    let action: () -> Void

    // MARK: - UI

    var body: some View {
        VStack {
            Button {
                action()
            } label: {
                Text(text)
                    .font(Constants.Fonts.title1)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Constants.Colors.resellPurple)
                    .foregroundStyle(Constants.Colors.white)
                    .clipShape(.capsule)
            }
        }
    }
}
