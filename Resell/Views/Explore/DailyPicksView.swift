//
//  DailyPicksView.swift
//  Resell
//
//  Created by Andrew Gao on 9/3/26.
//

import SwiftUI

/// See More screen for the Daily Picks rail: the full grid of the day's picks.
struct DailyPicksView: View {

    // MARK: - Properties

    @ObservedObject private var viewModel = ExploreViewModel.shared

    // MARK: - UI

    var body: some View {
        ScrollView(.vertical) {
            ProductsGalleryView(items: viewModel.dailyPicks)
        }
        .background(Constants.Colors.white)
        .loadingView(isLoading: viewModel.isLoadingDailyPicks)
        .emptyState(
            isEmpty: viewModel.dailyPicks.isEmpty && !viewModel.isLoadingDailyPicks,
            title: "No daily picks yet",
            text: "Check back soon for popular listings from the last day."
        )
        .refreshable {
            await viewModel.loadDailyPicks(forceRefresh: true, forSeeMore: true)
        }
        .task {
            await viewModel.loadDailyPicks(forSeeMore: true)
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton()
            }

            ToolbarItem(placement: .principal) {
                Text("Daily Picks")
                    .font(Constants.Fonts.h2)
                    .foregroundStyle(Constants.Colors.black)
            }
        }
    }
}
