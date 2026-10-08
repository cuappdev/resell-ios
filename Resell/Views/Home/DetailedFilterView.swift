//
//  DetailedFilterView.swift
//  Resell
//
//  Created by Charles Liggins on 4/27/25.
//

import SwiftUI

// TODO: Consolidate SavedView and DetailedFilterView into one view...
struct DetailedFilterView: View {

    // MARK: - Properties

    @State private var presentPopup = false
    @State private var searchText = ""
    @State private var isSearchExpanded = false
    @State private var isShowingSearchHistory = true
    @FocusState private var searchFocused: Bool

    @EnvironmentObject var router: Router
    @EnvironmentObject private var mainViewModel: MainViewModel

    let filter: FilterCategory

    @StateObject private var filtersViewModel = FiltersViewModel(isHome: false)
    @ObservedObject private var viewModel = HomeViewModel.shared

    /// A search has run, so the grid shows its matches instead of the whole category.
    private var isShowingSearchResults: Bool {
        isSearchExpanded && !isShowingSearchHistory
    }

    /// The search card and its history cover the grid, which shouldn't scroll behind it.
    private var isSearchPanelBlocking: Bool {
        isSearchExpanded && isShowingSearchHistory
    }

    private var displayedItems: [Post] {
        isShowingSearchResults
            ? filtersViewModel.searchedDetailedFilterItems
            : filtersViewModel.detailedFilterItems
    }

    // MARK: - UI

    var body: some View {
        ScrollView(.vertical, showsIndicators: !isSearchExpanded) {
            ProductsGalleryView(items: displayedItems)
                .padding(.top, 12)
        }
        .scrollDisabled(isSearchPanelBlocking)
        .background(Constants.Colors.white)
        .loadingView(isLoading: viewModel.isLoading)
        .emptyState(
            isEmpty: displayedItems.isEmpty && !isSearchPanelBlocking,
            title: isShowingSearchResults
                ? "No results"
                : "No \(filter.title) posts",
            text: isShowingSearchResults
                ? "No posts match '\(searchText)'"
                : "Posts in the \(filter.title) category will be displayed here."
        )
        .overlay(alignment: .top) {
            if isSearchExpanded {
                searchOverlay
            }
        }
        .onAppear {
            viewModel.getBlockedUsers()
        }
        .task {
            await loadCategoryPosts()
        }
        .onChange(of: isSearchExpanded, perform: handleSearchExpansionChange)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton(style: .systemChevronResizable(width: 12, height: 20))
            }

            ToolbarItem(placement: .principal) {
                Text(filter.title)
                    .font(Constants.Fonts.h2)
                    .foregroundStyle(Constants.Colors.black)
            }

            ToolbarItem(placement: .topBarTrailing) {
                searchButton
            }

            ToolbarItem(placement: .topBarTrailing) {
                filterButton
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $presentPopup) {
            FilterView(home: false, isPresented: $presentPopup)
                .environmentObject(filtersViewModel)
        }
    }

    private var searchButton: some View {
        Button {
            isSearchExpanded = true
        } label: {
            Icon(image: "search")
        }
        .disabled(isSearchExpanded)
    }

    private var filterButton: some View {
        Button {
            presentPopup = true
        } label: {
            Image("filters")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 19)
        }
    }

    private var searchOverlay: some View {
        SearchPanel(
            placeholder: "Search in \(filter.title)",
            text: $searchText,
            history: Array(mainViewModel.searchHistory.prefix(5)),
            showsHistory: isShowingSearchHistory,
            isFocused: $searchFocused,
            onSubmit: runSearch,
            onDismiss: {
                withAnimation(.snappy(duration: 0.2)) { isSearchExpanded = false }
            }
        )
    }

    // MARK: - Private Methods

    private func loadCategoryPosts() async {
        do {
            try await filtersViewModel.initializeDetailedFilter(category: filter.title)
            filtersViewModel.clearFilterSearch()
        } catch {
            NetworkManager.shared.logger.error("Error in DetailedFilterView.loadCategoryPosts: \(error)")
        }
    }

    private func handleSearchExpansionChange(_ isExpanded: Bool) {
        if isExpanded {
            isShowingSearchHistory = true
            Task { @MainActor in
                await Task.yield()
                searchFocused = true
            }
        } else {
            searchText = ""
            isShowingSearchHistory = true
            searchFocused = false
            filtersViewModel.clearFilterSearch()
        }
    }

    private func runSearch(_ query: String) {
        guard !query.isEmpty else { return }
        searchFocused = false
        isShowingSearchHistory = false
        mainViewModel.saveSearchQuery(query)
        filtersViewModel.searchWithinFilter(query: query)
    }
}
