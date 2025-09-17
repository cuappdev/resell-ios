//
//  HomeView.swift
//  Resell
//
//  Created by Richie Sun on 9/11/24.
//

import Kingfisher
import OAuth2
import SwiftUI

struct HomeView: View {

    @EnvironmentObject private var mainViewModel: MainViewModel
    @EnvironmentObject var router: Router
    @EnvironmentObject private var viewModel: HomeViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerView

            filtersView
                .padding(.bottom, 12)

            ProductsGalleryView(items: viewModel.filteredItems) {
                if viewModel.selectedFilter == "Recent" {
                    viewModel.fetchMoreItems()
                }
            }
            .emptyState(isEmpty: viewModel.filteredItems.isEmpty, title: "No posts found", text: "Check back later.")
        }
        .background(Constants.Colors.white)
        .overlay(alignment: .bottomTrailing) {
            ExpandableAddButton()
        }
        .onAppear {
            viewModel.getAllPosts()
            viewModel.getBlockedUsers()

            withAnimation {
                mainViewModel.hidesTabBar = false
            }
        }
        .refreshable {
            viewModel.getAllPosts()
        }
        .navigationBarBackButtonHidden()
    }

    private var headerView: some View {
        HStack {
            Text("resell")
                .font(Constants.Fonts.resellHeader)
                .foregroundStyle(Constants.Colors.resellGradient)

            Spacer()

            Button(action: {
                router.push(.search(nil))
            }, label: {
                Icon(image: "search")
            })
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
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
            .padding(.leading, Constants.Spacing.horizontalPadding)
            .padding(.vertical, 1)
        }
    }
}
