//
//  TrendingView.swift
//  Resell
//

import SwiftUI

struct TrendingView: View {
    let category: FilterCategory

    @ObservedObject private var viewModel = ExploreViewModel.shared

    var body: some View {
        ScrollView(.vertical) {
            ProductsGalleryView(items: viewModel.trendingDetailPosts)
        }
        .background(Constants.Colors.white)
        .loadingView(isLoading: viewModel.isLoadingTrendingDetails)
        .emptyState(
            isEmpty: viewModel.trendingDetailPosts.isEmpty
                && !viewModel.isLoadingTrendingDetails,
            title: "No trending \(category.title) posts",
            text: "Trending posts in this category will be displayed here."
        )
        .refreshable {
            await viewModel.loadTrendingDetails(
                category: category,
                forceRefresh: true
            )
        }
        .task(id: category.id) {
            await viewModel.loadTrendingDetails(category: category)
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton()
            }

            ToolbarItem(placement: .principal) {
                Text("Trending in \(category.title)")
                    .font(Constants.Fonts.h2)
                    .foregroundStyle(Constants.Colors.black)
            }
        }
    }
}
