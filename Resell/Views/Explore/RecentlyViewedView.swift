//
//  RecentlyViewedView.swift
//  Resell
//
//  Created by Andrew Gao on 9/3/26.
//

import SwiftUI

/// Every listing the user has recently opened, newest first.
struct RecentlyViewedView: View {

    // MARK: - Properties

    @ObservedObject private var viewModel = RecentlyViewedViewModel.shared

    // MARK: - UI

    var body: some View {
        ScrollView(.vertical) {
            ProductsGalleryView(items: viewModel.posts)
        }
        .background(Constants.Colors.white)
        .loadingView(isLoading: viewModel.isLoading && viewModel.posts.isEmpty)
        .emptyState(
            isEmpty: viewModel.posts.isEmpty && !viewModel.isLoading,
            title: "No recently viewed posts",
            text: "Listings you open will show up here."
        )
        .refreshable {
            await viewModel.loadAllPosts(forceRefresh: true)
        }
        .task {
            await viewModel.loadAllPosts()
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton()
            }

            ToolbarItem(placement: .principal) {
                Text("Recently Viewed")
                    .font(Constants.Fonts.h2)
                    .foregroundStyle(Constants.Colors.black)
            }
        }
    }
}
