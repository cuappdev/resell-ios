//
//  SavedView.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import SwiftUI

struct SavedView: View {

    @EnvironmentObject var router: Router
    @StateObject private var viewModel = HomeViewModel.shared

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerView
                ProductsGalleryView(items: viewModel.savedItems)
            }
        }
        .background(Constants.Colors.white)
        .loadingView(isLoading: viewModel.isLoading)
        .emptyState(isEmpty: $viewModel.savedItems.isEmpty, title: "No saved posts", text: "Posts you have bookmarked will be displayed here.")
        .refreshable {
            viewModel.getSavedPosts() {}
        }
        .onAppear {
            viewModel.getSavedPosts() {}
        }
    }

    private var headerView: some View {
        HStack {
            Text("Saved")
                .font(Constants.Fonts.h1)
                .foregroundStyle(Constants.Colors.black)

            Spacer()

            Button(action: {
                //TODO: Search Endpoint
            }, label: {
                Icon(image: "search")
            })
        }
        .padding(.horizontal, 25)
    }
}
