//
//  SearchResultsView.swift
//  Resell
//
//  Created by Andrew Gao on 9/30/26.
//

import SwiftUI

/// What a feed shows under an expanded `SearchPanel` once a query has run: a
/// spinner while it loads, a "No results" message, or the matching listings.
struct SearchResultsView: View {

    // MARK: - Properties

    let isLoading: Bool
    let items: [Post]

    // MARK: - UI

    var body: some View {
        if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 80)
        } else if items.isEmpty {
            noResultsView
        } else {
            ProductsGalleryView(items: items)
        }
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Text("No results")
                .font(Constants.Fonts.h2)
                .foregroundStyle(Constants.Colors.black)

            Text("Try a different search term")
                .font(Constants.Fonts.body1)
                .foregroundStyle(Constants.Colors.secondaryGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}
