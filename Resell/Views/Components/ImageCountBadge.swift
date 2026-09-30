//
//  ImageCountBadge.swift
//  Resell
//
//  Created by Andrew Gao on 9/30/26.
//

import SwiftUI

/// "2 / 5" capsule laid over a photo carousel to show which image is on screen.
struct ImageCountBadge: View {

    // MARK: - Properties

    /// Zero-based index of the photo on screen.
    let currentIndex: Int
    let count: Int
    var font: Font = Constants.Fonts.title3

    // MARK: - UI

    var body: some View {
        Text("\(currentIndex + 1) / \(count)")
            .font(font)
            .foregroundStyle(Constants.Colors.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Constants.Colors.black.opacity(0.55), in: Capsule())
            .accessibilityLabel("Image \(currentIndex + 1) of \(count)")
    }
}
