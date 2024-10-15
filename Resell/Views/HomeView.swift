//
//  HomeView.swift
//  Resell
//
//  Created by Richie Sun on 9/11/24.
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject private var mainViewModel: MainViewModel
    @StateObject private var viewModel = HomeViewModel.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView

                filtersView

                ProductsGalleryView(items: viewModel.allItems)
            }
            .background(Constants.Colors.white)
            .overlay(alignment: .bottomTrailing) {
                ExpandableAddButton()
                    .padding(.trailing, Constants.Spacing.horizontalPadding)
                    .padding(.bottom, Constants.Spacing.horizontalPadding)
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text("resell")
                .font(Constants.Fonts.resellHeader)
                .foregroundStyle(Constants.Colors.resellGradient)

            Spacer()

            Button(action: {
                // TODO: Search Endpoint
            }, label: {
                Icon(image: "search")
            })
        }
        .padding(.horizontal, 25)
    }

    private var filtersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Constants.filters, id: \.id) { filter in
                    FilterButton(filter: filter, isSelected: viewModel.selectedFilter == filter.title) {
                        viewModel.selectedFilter = filter.title
                    }
                }
            }
            .padding(.leading, 25)
            .padding(.vertical, 1)
            .padding(.bottom, 12)
        }
    }
}

#Preview {
    HomeView()
}
