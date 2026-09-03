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

    @EnvironmentObject var router: Router
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

    /// True while the search card covers the feed and nothing has been searched
    /// yet — the content underneath should not scroll behind it.
    private var isSearchPanelBlocking: Bool {
        isSearchExpanded && searchViewModel.isSearching
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: !isSearchPanelBlocking) {
            if isSearchExpanded && !searchViewModel.isSearching {
                searchResultsContent
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
        .onChange(of: isSearchExpanded) { isExpanded in
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
        .onChange(of: searchFocused) { focused in
            if focused { searchViewModel.isSearching = true }
        }
        .onAppear {
            withAnimation { mainViewModel.hidesTabBar = false }
            Task {
                async let saved: () = homeViewModel.getSavedPosts()
                async let recent: () = recentlyViewed.loadPreviewPosts()
                async let explore: () = exploreViewModel.loadAll()
                await saved
                await recent
                await explore
                exploreViewModel.applyKnownSaveCounts()
            }
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
                            ExploreCollageCard(
                                title: "Saved",
                                subtitle: "\(homeViewModel.savedItems.count)",
                                posts: homeViewModel.savedItems
                            ) {
                                router.push(.saved)
                            }
                            .frame(width: collageCardWidth)
                        }

                        if !recentlyViewed.posts.isEmpty {
                            ExploreCollageCard(
                                title: "Recently Viewed",
                                subtitle: nil,
                                posts: recentlyViewed.posts
                            ) {
                                router.push(.recentlyViewed)
                            }
                            .frame(width: collageCardWidth)
                        }
                    }
                    .padding(.horizontal, Constants.Spacing.horizontalPadding)
                }
            }
        }
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

    private let collageCardSpacing: CGFloat = 12

    /// A bit wider than half-screen so the pair peeks into horizontal scroll.
    private var collageCardWidth: CGFloat {
        let horizontalPadding = Constants.Spacing.horizontalPadding * 2
        return (UIScreen.width - horizontalPadding - collageCardSpacing) / 2 + 14
    }

    // MARK: - Search

    @ViewBuilder
    private var searchResultsContent: some View {
        if searchViewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 80)
        } else if searchViewModel.searchedItems.isEmpty {
            VStack(spacing: 12) {
                Text("No results")
                    .font(Constants.Fonts.h2)
                    .foregroundStyle(Constants.Colors.black)

                Text("Try a different search term")
                    .font(Constants.Fonts.body1)
                    .foregroundStyle(Constants.Colors.secondaryGray)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
        } else {
            ProductsGalleryView(items: searchViewModel.searchedItems)
        }
    }

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
            Button {
                isSearchExpanded = true
            } label: {
                HStack(spacing: 8) {
                    Image("search")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)

                    Text("What are you looking for?")
                        .font(Constants.Fonts.body2)
                        .foregroundStyle(Constants.Colors.secondaryGray)
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .frame(height: toolbarControlHeight)
            .modifier(GlassToolbarModifier())
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
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
