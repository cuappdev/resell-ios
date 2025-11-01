//
//  EmptyState.swift
//  Resell
//
//  Created by Richie Sun on 11/7/24.
//

import SwiftUI

/// A reusable view modifier that overlays an empty state view with a title and message when a specified condition is met.
struct EmptyStateModifier: ViewModifier {

    // MARK: - Properties

    /// Determines if the empty state overlay should be displayed.
    let isEmpty: Bool

    /// The title displayed in the empty state view.
    let title: String

    /// The descriptive text displayed in the empty state view.
    let text: String

    // MARK: - ViewModifier

    func body(content: Content) -> some View {
        ZStack {
            content

            if isEmpty {
                VStack(spacing: 16) {
                    Spacer()

                    Text(title)
                        .font(Constants.Fonts.h2)
                        .foregroundStyle(Constants.Colors.black)

                    Text(text)
                        .font(Constants.Fonts.body1)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Constants.Colors.secondaryGray)

                    Spacer()
                }
                .frame(width: 300)
            }
        }
    }
}

// MARK: - View Extension

extension View {

    /// - Displays an overlay with a title and text when `isEmpty` is true.
    /// - `title` is shown in a bold, large font .
    /// - `text` is displayed in a regular font with center alignment.
    func emptyState(isEmpty: Bool, title: String, text: String) -> some View {
        self.modifier(EmptyStateModifier(isEmpty: isEmpty, title: title, text: text))
    }
}
