//
//  ExploreView.swift
//  Resell
//

import SwiftUI

struct ExploreView: View {

    @EnvironmentObject var router: Router
    @EnvironmentObject private var mainViewModel: MainViewModel

    @ObservedObject private var homeViewModel = HomeViewModel.shared
    @ObservedObject private var recentlyViewed = RecentlyViewedViewModel.shared
    @ObservedObject private var exploreViewModel = ExploreViewModel.shared
    /// Local instance so Explore search doesn't clobber Home while both tabs stay mounted.
    @StateObject private var searchViewModel = SearchViewModel()

    @FocusState private var searchFocused: Bool

    @State private var expand: Bool = false
    @State private var searchText: String = ""

    private var toolbarControlHeight: CGFloat { 40 }

    var body: some View {
        ScrollView(.vertical, showsIndicators: !expand) {
            if expand && !searchViewModel.isSearching {
                searchResultsContent
                    .padding(.top, 12)
            } else {
                exploreContent
                    .padding(.top, 12)
            }
        }
        .scrollDisabled(expand)
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 44)
        }
        .overlay(alignment: .top) {
            searchToolbar
        }
        .toolbar(.hidden, for: .navigationBar)
        .background(Constants.Colors.white)
        .navigationBarBackButtonHidden()
        .onChange(of: expand) { isExpanded in
            if isExpanded {
                searchViewModel.isSearching = true
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
                .font(.custom("Rubik-Medium", size: 22))
                .foregroundStyle(Constants.Colors.black)
                .padding(.horizontal, Constants.Spacing.horizontalPadding)

            if homeViewModel.savedItems.isEmpty && recentlyViewed.posts.isEmpty {
                emptyJustForYou
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
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

    private var collageCardWidth: CGFloat {
        let horizontalPadding = Constants.Spacing.horizontalPadding * 2
        let spacing: CGFloat = 12
        // A bit wider than half-screen so the pair peeks into horizontal scroll.
        return (UIScreen.main.bounds.width - horizontalPadding - spacing) / 2 + 14
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

    private var searchToolbar: some View {
        Group {
            if expand {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        TextField(
                            "",
                            text: $searchText,
                            prompt: Text("What are you looking for?")
                                .foregroundColor(Constants.Colors.secondaryGray)
                        )
                        .font(Constants.Fonts.body2)
                        .foregroundStyle(Constants.Colors.black)
                        .submitLabel(.search)
                        .focused($searchFocused)
                        .onSubmit { runSearch(searchText) }

                        Button {
                            withAnimation(.snappy(duration: 0.2)) { expand = false }
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

                    if searchViewModel.isSearching && !mainViewModel.searchHistory.isEmpty {
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
            } else {
                Button {
                    expand = true
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
