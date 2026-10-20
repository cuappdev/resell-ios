//
//  FiltersViewModel.swift
//  Resell
//
//  Created by Charles Liggins on 9/26/25.
//

import SwiftUI
import Combine

@MainActor
class FiltersViewModel: ObservableObject {

    // MARK: - Properties

    @Published var categoryFilters: Set<String> = []
    @Published var conditionFilters: Set<String> = []
    @Published var lowValue: Double = 0
    @Published var highValue: Double = 1000
    @Published var selectedSort: SortOption? = nil
    @Published var detailedFilterItems: [Post] = []
    @Published var searchedDetailedFilterItems: [Post] = []
    @Published var isSearching: Bool = false

    let isHome: Bool

    private var baseCategory: String? = nil // Store the base category for detailed view

    /// What the posts on screen are filtered by. The sheet's controls differ from it
    /// while the user has changes they haven't applied.
    private var appliedSelection = FilterSelection()
    private var page = 1
    private var hasMorePages = true
    private var isFetchingNextPage = false

    /// Whether "Apply filters" would change the posts on screen.
    var hasUnappliedChanges: Bool {
        currentSelection != appliedSelection
    }

    private var currentSelection: FilterSelection {
        FilterSelection(
            categories: categoryFilters,
            conditions: conditionFilters,
            lowPrice: lowValue,
            highPrice: highValue,
            sort: selectedSort ?? .any
        )
    }

    /// What Reset returns to: no filters on Home, just the page's own category on a category page.
    private var defaultSelection: FilterSelection {
        FilterSelection(categories: baseCategory.map { [$0] } ?? [])
    }

    init(isHome: Bool = false) {
        self.isHome = isHome
    }

    // MARK: - Functions

    func initializeDetailedFilter(category: String) async throws {
        baseCategory = category
        categoryFilters = [category] // Pre-populate with the category
        try await applyFilters(homeViewModel: HomeViewModel.shared)
    }
    
    func searchWithinFilter(query: String) {
        guard !query.isEmpty else {
            searchedDetailedFilterItems = detailedFilterItems
            return
        }
        
        isSearching = true
        
        // Search within already filtered items
        searchedDetailedFilterItems = detailedFilterItems.filter { post in
            post.title.localizedCaseInsensitiveContains(query) ||
            post.description.localizedCaseInsensitiveContains(query) == true ||
            post.user?.username.localizedCaseInsensitiveContains(query) == true
        }
        
        isSearching = false
    }
    
    func clearFilterSearch() {
        searchedDetailedFilterItems = detailedFilterItems
    }

    /// Shows the first page of posts matching the sheet's selection, in the home feed or on
    /// the category page. On Home, selecting nothing returns the feed to its regular listings.
    func applyFilters(homeViewModel: HomeViewModel) async throws {
        let selection = currentSelection

        if isHome && selection == FilterSelection() {
            appliedSelection = selection
            homeViewModel.clearFilters()
            return
        }

        do {
            let postsResponse = try await NetworkManager.shared.getUnifiedFilteredPosts(filters: FilterPostsUnifiedRequest(selection))
            appliedSelection = selection
            page = 1
            hasMorePages = !postsResponse.posts.isEmpty

            if isHome {
                homeViewModel.filteredItems = postsResponse.posts
                homeViewModel.isFilteredFeed = true
            } else {
                detailedFilterItems = postsResponse.posts
                clearFilterSearch()
            }
        } catch {
            NetworkManager.shared.logger.error("Error in FiltersViewModel.applyFilters: \(error)")
        }
    }

    /// Appends the next page of posts matching the applied filters, for when the user scrolls
    /// near the end of the list.
    func fetchMoreFilteredPosts(homeViewModel: HomeViewModel) {
        guard hasMorePages, !isFetchingNextPage else { return }

        let selection = appliedSelection
        let nextPage = page + 1
        isFetchingNextPage = true

        Task {
            defer { isFetchingNextPage = false }

            do {
                let postsResponse = try await NetworkManager.shared.getUnifiedFilteredPosts(
                    filters: FilterPostsUnifiedRequest(selection),
                    page: nextPage
                )
                // Filters applied while this page loaded have replaced the list it belonged to.
                guard selection == appliedSelection, nextPage == page + 1 else { return }

                guard !postsResponse.posts.isEmpty else {
                    hasMorePages = false
                    return
                }

                page = nextPage
                appendUnseenPosts(postsResponse.posts, homeViewModel: homeViewModel)
            } catch {
                NetworkManager.shared.logger.error("Error in FiltersViewModel.fetchMoreFilteredPosts: \(error)")
            }
        }
    }

    /// Puts the sheet's controls back to the applied filters, so the sheet always opens on
    /// what the posts are filtered by.
    func discardUnappliedChanges() {
        select(appliedSelection)
    }

    func resetFilters(homeViewModel: HomeViewModel) {
        select(defaultSelection)

        if isHome {
            appliedSelection = defaultSelection
            homeViewModel.clearFilters()
        } else {
            Task {
                try? await applyFilters(homeViewModel: homeViewModel)
            }
        }
    }

    // MARK: - Private Methods

    private func select(_ selection: FilterSelection) {
        categoryFilters = selection.categories
        conditionFilters = selection.conditions
        lowValue = selection.lowPrice
        highValue = selection.highPrice
        selectedSort = selection.sort
    }

    /// Skips posts already on screen: a listing created between page loads shifts later pages
    /// by one, which would otherwise show its neighbor twice.
    private func appendUnseenPosts(_ posts: [Post], homeViewModel: HomeViewModel) {
        let shownPosts = isHome ? homeViewModel.filteredItems : detailedFilterItems
        let shownIDs = Set(shownPosts.map(\.id))
        let unseenPosts = posts.filter { !shownIDs.contains($0.id) }

        if isHome {
            homeViewModel.filteredItems += unseenPosts
        } else {
            detailedFilterItems += unseenPosts
        }
    }
}
