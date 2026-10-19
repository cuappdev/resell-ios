//
//  EventSpaceCard.swift
//  Resell
//
//  Created by Andrew Gao on 10/14/26.
//

import SwiftUI

/// Explore card for one event space: the event's photo under a dark tint, with
/// its title and listing count along the bottom.
struct EventSpaceCard: View {

    // MARK: - Properties

    let event: EventSpace
    /// Hidden while unknown or zero.
    let listingCount: Int?
    let action: () -> Void

    /// Matches `ExploreCollageCard` so the Explore rows line up.
    private let aspectRatio: CGFloat = 1.12
    private let cornerRadius: CGFloat = 12
    private let tintOpacity: CGFloat = 0.3
    private let iconHeight: CGFloat = 15
    private let captionInsets = EdgeInsets(top: 0, leading: 8, bottom: 20, trailing: 16)

    private var visibleListingCount: Int? {
        guard let listingCount, listingCount > 0 else { return nil }
        return listingCount
    }

    // MARK: - UI

    var body: some View {
        Button(action: action) {
            Color.clear
                .aspectRatio(aspectRatio, contentMode: .fit)
                .background {
                    Image(event.cardImageName)
                        .resizable()
                        .scaledToFill()
                }
                .overlay(Constants.Colors.black.opacity(tintOpacity))
                .overlay(alignment: .bottom) {
                    caption
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var caption: some View {
        HStack(spacing: Constants.Spacing.spacing8) {
            Image("calendar-internal")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: iconHeight)

            Text(event.title)
                .lineLimit(2)

            Spacer(minLength: Constants.Spacing.spacing8)

            if let visibleListingCount {
                Text("\(visibleListingCount)")
            }
        }
        .font(Constants.Fonts.title3)
        .foregroundStyle(Constants.Colors.white)
        .padding(captionInsets)
    }

    private var accessibilityLabel: String {
        guard let visibleListingCount else { return event.title }
        return "\(event.title), \(visibleListingCount) \(visibleListingCount == 1 ? "listing" : "listings")"
    }
}
