//
//  ExploreView.swift
//  Resell
//
//  Created by Andrew Gao on 9/3/26.
//

import SwiftUI

/// Discovery tab: category shortcuts, the viewer's own collections, and the
/// Daily Picks / Trending rails, behind a search field that takes over the
/// screen when tapped.
struct ExploreView: View {

    // MARK: - Properties

    @EnvironmentObject private var router: Router
    @EnvironmentObject private var mainViewModel: MainViewModel

    @ObservedObject private var homeViewModel = HomeViewModel.shared
    @ObservedObject private var recentlyViewed = RecentlyViewedViewModel.shared
    @ObservedObject private var exploreViewModel = ExploreViewModel.shared
    /// Local instance so Explore search doesn't clobber Home's while both tab
    /// roots stay mounted.
    @StateObject private var searchViewModel = SearchViewModel()

    @FocusState private var searchFocused: Bool

    @State private var isSearchExpanded: Bool = false
    @State private var searchText: String = ""

    private let toolbarControlHeight: CGFloat = 40
    private let collageCardSpacing: CGFloat = 12

    /// True while the search card covers the feed and nothing has been searched
    /// yet — the content underneath should not scroll behind it.
    private var isSearchPanelBlocking: Bool {
        isSearchExpanded && searchViewModel.isSearching
    }

    /// A bit wider than half-screen so the pair peeks into horizontal scroll.
    private var collageCardWidth: CGFloat {
        let horizontalPadding = Constants.Spacing.horizontalPadding * 2
        return (UIScreen.width - horizontalPadding - collageCardSpacing) / 2 + 14
    }

    // MARK: - UI

    var body: some View {
        ScrollView(.vertical, showsIndicators: !isSearchPanelBlocking) {
            if isSearchExpanded && !searchViewModel.isSearching {
                SearchResultsView(
                    isLoading: searchViewModel.isLoading,
                    items: searchViewModel.searchedItems
                )
                .padding(.top, 12)
            } else {
                exploreContent
                    .padding(.top, 12)
            }
        }
        .scrollDisabled(isSearchPanelBlocking)
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 44)
        }
        .overlay(alignment: .top) {
            searchToolbar
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(Constants.Colors.white)
        .navigationBarBackButtonHidden()
        .onChange(of: isSearchExpanded, perform: handleSearchExpansionChange)
        .onChange(of: searchFocused) { focused in
            if focused { searchViewModel.isSearching = true }
        }
        .onAppear {
            withAnimation { mainViewModel.hidesTabBar = false }
        }
        .task {
            await loadExploreContent()
        }
        .onChange(of: homeViewModel.savedItems) { _ in
            exploreViewModel.applyKnownSaveCounts()
        }
    }

    // MARK: - Explore Content

    private var exploreContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            CategoriesView()

            justForYouSection

            ExploreDailyPicksSection()

            ExploreTrendingSection()
        }
        .padding(.bottom, 24)
    }

    private var justForYouSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Just For You")
                .font(Constants.Fonts.h2)
                .foregroundStyle(Constants.Colors.black)
                .padding(.horizontal, Constants.Spacing.horizontalPadding)

            if homeViewModel.savedItems.isEmpty && recentlyViewed.posts.isEmpty {
                emptyJustForYou
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: collageCardSpacing) {
                        if !homeViewModel.savedItems.isEmpty {
                            savedCollage
                        }

                        if !recentlyViewed.posts.isEmpty {
                            recentlyViewedCollage
                        }
                    }
                    .padding(.horizontal, Constants.Spacing.horizontalPadding)
                }
            }
        }
    }

    private var savedCollage: some View {
        ExploreCollageCard(
            title: "Saved",
            subtitle: "\(homeViewModel.savedItems.count)",
            posts: homeViewModel.savedItems
        ) {
            router.push(.saved)
        }
        .frame(width: collageCardWidth)
    }

    private var recentlyViewedCollage: some View {
        ExploreCollageCard(
            title: "Recently Viewed",
            subtitle: nil,
            posts: recentlyViewed.posts
        ) {
            router.push(.recentlyViewed)
        }
        .frame(width: collageCardWidth)
    }

    private var emptyJustForYou: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Constants.Colors.stroke, lineWidth: 1)

            VStack(spacing: 6) {
                Text("Nothing here yet")
                    .font(Constants.Fonts.title2)
                    .foregroundStyle(Constants.Colors.black)

                Text("Save listings or browse products to fill this section.")
                    .font(Constants.Fonts.subtitle1)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .frame(height: 110)
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
    }

    // MARK: - Search

    @ViewBuilder
    private var searchToolbar: some View {
        if isSearchExpanded {
            SearchPanel(
                placeholder: "What are you looking for?",
                text: $searchText,
                history: Array(mainViewModel.searchHistory.prefix(5)),
                showsHistory: searchViewModel.isSearching,
                isFocused: $searchFocused,
                onSubmit: runSearch,
                onDismiss: {
                    withAnimation(.snappy(duration: 0.2)) { isSearchExpanded = false }
                }
            )
        } else {
            SearchPill(placeholder: "What are you looking for?", height: toolbarControlHeight) {
                isSearchExpanded = true
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
        }
    }

    // MARK: - Private Methods

    private func loadExploreContent() async {
        async let saved: () = homeViewModel.getSavedPosts()
        async let recent: () = recentlyViewed.loadPreviewPosts()
        async let explore: () = exploreViewModel.loadAll()
        await saved
        await recent
        await explore
        exploreViewModel.applyKnownSaveCounts()
    }

    private func handleSearchExpansionChange(_ isExpanded: Bool) {
        if isExpanded {
            searchViewModel.isSearching = true
            // Focus after the panel paints; creating the field and raising
            // the keyboard in one frame drops the first animation.
            Task { @MainActor in
                await Task.yield()
                searchFocused = true
            }
        } else {
            searchText = ""
            searchViewModel.isSearching = true
            searchViewModel.searchedItems = []
            searchFocused = false
        }
    }

    private func runSearch(_ query: String) {
        guard !query.isEmpty else { return }
        searchFocused = false
        searchViewModel.searchItems(
            with: query,
            userID: nil,
            saveQuery: true,
            mainViewModel: mainViewModel
        ) {}
    }
}
