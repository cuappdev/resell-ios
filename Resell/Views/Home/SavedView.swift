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
        NavigationStack(path: $router.path) {
            ZStack {
                VStack(spacing: 0) {
                    headerView
                    ProductsGalleryView(items: viewModel.savedItems)
                }

                if viewModel.savedItems.isEmpty {
                    emptyState
                }
            }
            .background(Constants.Colors.white)

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

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("No saved posts")
                .font(Constants.Fonts.h2)
                .foregroundStyle(Constants.Colors.black)

            Text("Posts you have bookmarked will be displayed here")
                .font(Constants.Fonts.body1)
                .multilineTextAlignment(.center)
                .foregroundStyle(Constants.Colors.secondaryGray)
        }
        .frame(width: 300)
    }
}
