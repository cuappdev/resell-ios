//
//  DetailedFilterView.swift
//  Resell
//
//  Created by Charles Liggins on 4/27/25.
//

import SwiftUI

// TODO: Consolidate SavedView and DetailedFilterView into one view...
struct DetailedFilterView: View {
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

    private var displayedItems: [Post] {
        if isSearchExpanded && !isShowingSearchHistory {
            return filtersViewModel.searchedDetailedFilterItems
        }
        return filtersViewModel.detailedFilterItems
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: !isSearchExpanded) {
            ProductsGalleryView(items: displayedItems)
                .padding(.top, 12)
        }
        .scrollDisabled(isSearchExpanded && isShowingSearchHistory)
        .background(Constants.Colors.white)
        .loadingView(isLoading: viewModel.isLoading)
        .emptyState(
            isEmpty: displayedItems.isEmpty && !(isSearchExpanded && isShowingSearchHistory),
            title: isSearchExpanded && !isShowingSearchHistory
                ? "No results"
                : "No \(filter.title) posts",
            text: isSearchExpanded && !isShowingSearchHistory
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
            Task {
                try await filtersViewModel.initializeDetailedFilter(category: filter.title)
                filtersViewModel.clearFilterSearch()
            }
        }
        .onChange(of: isSearchExpanded) { isExpanded in
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
                Button {
                    isSearchExpanded = true
                } label: {
                    Icon(image: "search")
                }
                .disabled(isSearchExpanded)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    presentPopup = true
                } label: {
                    Image("filters")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 19)
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $presentPopup) {
            FilterView(home: false, isPresented: $presentPopup)
                .environmentObject(filtersViewModel)
        }
    }

    private var searchOverlay: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                TextField(
                    "",
                    text: $searchText,
                    prompt: Text("Search in \(filter.title)")
                        .foregroundColor(Constants.Colors.secondaryGray)
                )
                .font(Constants.Fonts.body2)
                .foregroundStyle(Constants.Colors.black)
                .submitLabel(.search)
                .focused($searchFocused)
                .onSubmit { runSearch(searchText) }

                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        isSearchExpanded = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Constants.Colors.black)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if isShowingSearchHistory && !mainViewModel.searchHistory.isEmpty {
                Divider().padding(.horizontal, 4)

                let history = Array(mainViewModel.searchHistory.prefix(5))
                ForEach(history, id: \.self) { query in
                    Button {
                        searchText = query
                        runSearch(query)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "clock")
                                .font(.system(size: 13))
                                .foregroundStyle(Constants.Colors.secondaryGray)
                            Text(query)
                                .font(Constants.Fonts.body1)
                                .foregroundStyle(Constants.Colors.black)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if query != history.last {
                        Divider().padding(.horizontal, 4)
                    }
                }
                .padding(.bottom, 4)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Constants.Colors.white)
                .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 6)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .frame(maxWidth: .infinity)
    }

    private func runSearch(_ query: String) {
        guard !query.isEmpty else { return }
        searchFocused = false
        isShowingSearchHistory = false
        mainViewModel.saveSearchQuery(query)
        filtersViewModel.searchWithinFilter(query: query)
    }
}
