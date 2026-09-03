//
//  SearchPanel.swift
//  Resell
//
//  Created by Andrew Gao on 9/3/26.
//

import SwiftUI

/// The expanded search card that drops over a feed: a text field, a dismiss
/// control, and the caller's recent queries in the same rounded surface.
///
/// Home, Explore and the category browser all present this; only the collapsed
/// control that opens it differs between them.
///
/// The surface is deliberately opaque rather than glass. Materializing a glass
/// layer this large in the same frame the keyboard animates in is what made
/// opening search feel like a cold-start hang.
struct SearchPanel: View {

    let placeholder: String
    @Binding var text: String
    /// Recent queries to offer. Ignored while results are on screen.
    let history: [String]
    /// False once a search has run, so the card collapses back to just the field.
    let showsHistory: Bool
    @FocusState.Binding var isFocused: Bool
    let onSubmit: (String) -> Void
    let onDismiss: () -> Void

    private let cornerRadius: CGFloat = 22

    var body: some View {
        VStack(spacing: 0) {
            searchField

            if showsHistory && !history.isEmpty {
                Divider()
                    .padding(.horizontal, 4)

                historyList
            }
        }
        .background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Constants.Colors.white)
                .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 6)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .frame(maxWidth: .infinity)
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder)
                    .foregroundColor(Constants.Colors.secondaryGray)
            )
            .font(Constants.Fonts.body2)
            .foregroundStyle(Constants.Colors.black)
            .submitLabel(.search)
            .focused($isFocused)
            .onSubmit { onSubmit(text) }

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Constants.Colors.black)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close search")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var historyList: some View {
        ForEach(history, id: \.self) { query in
            Button {
                text = query
                onSubmit(query)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 13))
                        .foregroundStyle(Constants.Colors.secondaryGray)

                    Text(query)
                        .font(Constants.Fonts.body1)
                        .foregroundStyle(Constants.Colors.black)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if query != history.last {
                Divider()
                    .padding(.horizontal, 4)
            }
        }
        .padding(.bottom, 4)
    }
}
