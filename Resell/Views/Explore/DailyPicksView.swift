//
//  DailyPicksView.swift
//  Resell
//
//  Created by Andrew Gao on 9/3/26.
//

import SwiftUI

struct DailyPicksView: View {

    @ObservedObject private var viewModel = ExploreViewModel.shared

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
        .onAppear {
            Task {
                await viewModel.loadDailyPicks(forSeeMore: true)
            }
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
