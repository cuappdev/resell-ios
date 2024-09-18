//
//  BackButton.swift
//  Resell
//
//  Created by Richie Sun on 9/17/24.
//

import SwiftUI

/// Navigation back button, chevron
struct BackButton: View {

    // MARK: - Properties

    let dismiss: DismissAction

    // MARK: - UI

    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(.black)
        }
    }
}
