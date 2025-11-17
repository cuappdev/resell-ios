//
//  DetailedFilterView.swift
//  Resell
//
//  Created by Charles Liggins on 4/27/25.
//

import SwiftUI

// TODO: Consolidate SavedView and DetailedFilterView into one view...
struct DetailedFilterView: View {
    @State var presentPopup = false
    @State var searchText = ""
    @EnvironmentObject var router: Router
    let filter: FilterCategory
    
    @StateObject private var filtersViewModel = FiltersViewModel(isHome: false)
    @StateObject private var viewModel = HomeViewModel.shared
    
    // Computed property to show either searched or all filtered items
    private var displayedItems: [Post] {
        searchText.isEmpty ? filtersViewModel.detailedFilterItems : filtersViewModel.searchedDetailedFilterItems
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerView
                ScrollView(.vertical) {
                    ProductsGalleryView(items: displayedItems)
                }
            }
        }
        .background(Constants.Colors.white)
        .loadingView(isLoading: viewModel.isLoading)
        .emptyState(
            isEmpty: (displayedItems.isEmpty),
            title: searchText.isEmpty ? "No \(filter.title) posts" : "No results",
            text: searchText.isEmpty ? "Posts in the \(filter.title) category will be displayed here." : "No posts match '\(searchText)'"
        )
        .onAppear {
            viewModel.getBlockedUsers()
            Task {
                try await filtersViewModel.initializeDetailedFilter(category: filter.title)
                filtersViewModel.clearFilterSearch()
            }
        }
        .sheet(isPresented: $presentPopup) {
            FilterView(home: false, isPresented: $presentPopup)
                .environmentObject(filtersViewModel)
        }
    }

    private var headerView: some View {
        VStack {
            HStack(spacing: 64) {
                Button {
                    router.pop()
                } label: {
                    Image("chevron.left.white")
                        .resizable()
                        .frame(width: 36, height: 24)
                }
                
                Text(filter.title)
                    .font(Constants.Fonts.h1)
                    .foregroundStyle(Constants.Colors.black)
                
                Spacer()
            }
            .padding(.horizontal, 25)
            
            HStack {
                SearchBar(text: $searchText, placeholder: "Search in \(filter.title)", isEditable: true)
                    .onChange(of: searchText) { newValue in
                        filtersViewModel.searchWithinFilter(query: newValue)
                    }
                
                Button(action: {
                    presentPopup = true
                }, label: {
                    Image("filters")
                        .resizable()
                        .frame(width: 40, height: 40)
                })
            }
            .padding(.bottom, 12)
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
        }
    }
}
