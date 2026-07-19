//
//  RecentlyViewedView.swift
//  Resell
//

import SwiftUI

struct RecentlyViewedView: View {

    @EnvironmentObject var router: Router
    @ObservedObject private var viewModel = RecentlyViewedViewModel.shared

    var body: some View {
        ScrollView(.vertical) {
            ProductsGalleryView(items: viewModel.posts)
        }
        .background(Constants.Colors.white)
        .loadingView(isLoading: viewModel.isLoading)
        .emptyState(
            isEmpty: viewModel.posts.isEmpty,
            title: "No recently viewed posts",
            text: "Listings you open will show up here."
        )
        .refreshable {
            await viewModel.loadAllPosts(forceRefresh: true)
        }
        .onAppear {
            Task {
                await viewModel.loadAllPosts()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton()
            }

            ToolbarItem(placement: .principal) {
                Text("Recently Viewed")
                    .font(Constants.Fonts.h1)
                    .foregroundStyle(Constants.Colors.black)
            }
        }
    }
}
