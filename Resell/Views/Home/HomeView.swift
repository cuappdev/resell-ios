//
//  HomeView.swift
//  Resell
//
//  Created by Richie Sun on 9/11/24.
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject private var mainViewModel: MainViewModel
    @EnvironmentObject var router: Router
    @StateObject private var viewModel = HomeViewModel.shared

    var body: some View {
        NavigationStack(path: $router.path) {
            VStack(spacing: 0) {
                headerView

                filtersView

                ProductsGalleryView(items: viewModel.allItems)
            }
            .background(Constants.Colors.white)
            .overlay(alignment: .bottomTrailing) {
                ExpandableAddButton()
                    .padding(.bottom, 40)
            }
            .onAppear {
                print("Appear")
                withAnimation {
                    mainViewModel.hidesTabBar = false
                }
            }
            .navigationBarBackButtonHidden()
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

#Preview {
    HomeView()
}
