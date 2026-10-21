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

    /// What the sheet's controls are set to.
    @Published var selection = FilterSelection()
    @Published var detailedFilterItems: [Post] = []
    @Published var searchedDetailedFilterItems: [Post] = []
    @Published var isSearching: Bool = false

    let isHome: Bool

    private var baseCategory: String? = nil // Store the base category for detailed view

    /// What the posts on screen are filtered by. `selection` differs from it while the
    /// sheet has changes the user hasn't applied.
    private var appliedSelection = FilterSelection()
    private var page = 1
    private var hasMorePages = true
    private var isFetchingNextPage = false
    private let pageSize = 10

    /// Whether "Apply filters" would change the posts on screen.
    var hasUnappliedChanges: Bool {
        selection != appliedSelection
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
        selection.categories = [category] // Pre-populate with the category
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
    /// the category page.
    func applyFilters(homeViewModel: HomeViewModel) async throws {
        await showFirstPage(matching: selection, homeViewModel: homeViewModel)
    }

    /// Reloads the first page of the applied filters, for pull-to-refresh.
    func refreshFilteredPosts(homeViewModel: HomeViewModel) async {
        await showFirstPage(matching: appliedSelection, homeViewModel: homeViewModel)
    }

    /// Appends the next page of posts matching the applied filters, for when the user scrolls
    /// near the end of the list.
    func fetchMoreFilteredPosts(homeViewModel: HomeViewModel) {
        guard hasMorePages, !isFetchingNextPage else { return }

        let requestedSelection = appliedSelection
        let nextPage = page + 1
        isFetchingNextPage = true

        Task {
            defer { isFetchingNextPage = false }

            do {
                let postsResponse = try await NetworkManager.shared.getUnifiedFilteredPosts(
                    filters: FilterPostsUnifiedRequest(requestedSelection),
                    page: nextPage,
                    limit: pageSize
                )
                // Filters applied while this page loaded have replaced the list it belonged to.
                guard requestedSelection == appliedSelection, nextPage == page + 1 else { return }

                page = nextPage
                hasMorePages = postsResponse.posts.count == pageSize
                appendUnseenPosts(postsResponse.posts, homeViewModel: homeViewModel)
            } catch {
                NetworkManager.shared.logger.error("Error in FiltersViewModel.fetchMoreFilteredPosts: \(error)")
            }
        }
    }

    /// Puts the sheet's controls back to the applied filters, so the sheet always opens on
    /// what the posts are filtered by.
    func discardUnappliedChanges() {
        selection = appliedSelection
    }

    func resetFilters(homeViewModel: HomeViewModel) {
        selection = defaultSelection

        if isHome {
            appliedSelection = selection
            homeViewModel.clearFilters()
        } else {
            Task {
                try? await applyFilters(homeViewModel: homeViewModel)
            }
        }
    }

    // MARK: - Private Methods

    /// Replaces the posts on screen with the first page matching `filters`. On Home, an
    /// empty selection returns the feed to its regular listings instead.
    private func showFirstPage(matching filters: FilterSelection, homeViewModel: HomeViewModel) async {
        if isHome && filters == FilterSelection() {
            appliedSelection = filters
            homeViewModel.clearFilters()
            return
        }

        do {
            let postsResponse = try await NetworkManager.shared.getUnifiedFilteredPosts(
                filters: FilterPostsUnifiedRequest(filters),
                limit: pageSize
            )
            appliedSelection = filters
            page = 1
            hasMorePages = postsResponse.posts.count == pageSize

            if isHome {
                homeViewModel.filteredItems = postsResponse.posts
                homeViewModel.isFilteredFeed = true
            } else {
                detailedFilterItems = postsResponse.posts
                clearFilterSearch()
            }
        } catch {
            NetworkManager.shared.logger.error("Error in FiltersViewModel.showFirstPage: \(error)")
        }
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
