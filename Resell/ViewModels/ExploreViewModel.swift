//
//  ExploreViewModel.swift
//  Resell
//
//  Created by Andrew Gao on 9/3/26.
//

import SwiftUI

/// State behind the Explore tab's Daily Picks and Trending rails.
///
/// Shared so the Explore tab and its See More screens (`DailyPicksView`,
/// `TrendingView`) read the same cached lists instead of refetching them.
@MainActor
final class ExploreViewModel: ObservableObject {

    // MARK: - Properties

    static let shared = ExploreViewModel()

    @Published private(set) var dailyPicks: [Post] = []
    @Published private(set) var trendingPosts: [Post] = []
    @Published private(set) var trendingDetailPosts: [Post] = []
    @Published private(set) var isLoadingDailyPicks: Bool = false
    @Published private(set) var isLoadingTrending: Bool = false
    @Published private(set) var isLoadingTrendingDetails: Bool = false

    @Published var selectedTrendingCategory: FilterCategory = Constants.productCategories.first { $0.title == "Electronics" }
        ?? Constants.productCategories[0]

    /// Categories the Trending rail can switch between.
    let trendingCategories: [FilterCategory] = Constants.productCategories

    /// API category query value matching backend seed names (`ELECTRONICS`, …).
    var trendingCategoryAPIName: String {
        selectedTrendingCategory.title.uppercased()
    }

    private var lastDailyPicksFetch: Date?
    private var lastTrendingFetch: Date?
    private var lastTrendingCategoryKey: String?
    private var lastTrendingDetailCategoryKey: String?
    private let cacheValidityDuration: TimeInterval = 180

    private let previewLimit = 10
    private let seeMoreLimit = 40

    private init() {}

    // MARK: - Functions

    /// Loads both rails in parallel, reusing anything fetched in the last few minutes.
    func loadAll(forceRefresh: Bool = false) async {
        async let picks: () = loadDailyPicks(forceRefresh: forceRefresh)
        async let trending: () = loadTrending(forceRefresh: forceRefresh)
        await picks
        await trending
        applyKnownSaveCounts()
    }

    /// `/post/trending` does not reliably include `savers`, so overlay IDs
    /// from the current user's saved list (a lower bound, not a global total).
    func applyKnownSaveCounts() {
        let savedIDs = Set(HomeViewModel.shared.savedItems.map(\.id))
        guard !savedIDs.isEmpty else { return }
        trendingPosts = overlayKnownSaveCounts(savedIDs, on: trendingPosts)
        trendingDetailPosts = overlayKnownSaveCounts(savedIDs, on: trendingDetailPosts)
    }

    /// Loads Daily Picks: a short preview for the rail, or the longer list its
    /// See More screen shows when `forSeeMore` is true.
    func loadDailyPicks(forceRefresh: Bool = false, forSeeMore: Bool = false) async {
        let limit = forSeeMore ? seeMoreLimit : previewLimit

        if !forceRefresh,
           !forSeeMore,
           let lastFetch = lastDailyPicksFetch,
           Date().timeIntervalSince(lastFetch) < cacheValidityDuration,
           !dailyPicks.isEmpty {
            return
        }

        isLoadingDailyPicks = true
        defer { isLoadingDailyPicks = false }

        do {
            let response = try await NetworkManager.shared.getDailyPicks(limit: limit)
            dailyPicks = response.posts
            lastDailyPicksFetch = Date()
        } catch {
            NetworkManager.shared.logger.error("Failed to load daily picks: \(error)")
        }
    }

    /// Loads the Trending rail for `selectedTrendingCategory`.
    func loadTrending(forceRefresh: Bool = false) async {
        let categoryKey = trendingCategoryAPIName

        if !forceRefresh,
           lastTrendingCategoryKey == categoryKey,
           let lastFetch = lastTrendingFetch,
           Date().timeIntervalSince(lastFetch) < cacheValidityDuration,
           !trendingPosts.isEmpty {
            applyKnownSaveCounts()
            return
        }

        isLoadingTrending = true
        defer { isLoadingTrending = false }

        do {
            let response = try await NetworkManager.shared.getTrendingPosts(
                category: categoryKey,
                page: 1,
                limit: previewLimit
            )
            trendingPosts = response.posts
            lastTrendingFetch = Date()
            lastTrendingCategoryKey = categoryKey
            applyKnownSaveCounts()
        } catch {
            NetworkManager.shared.logger.error("Failed to load trending posts: \(error)")
            trendingPosts = []
        }
    }

    /// Switches the Trending rail to `category` and refetches it.
    func selectTrendingCategory(_ category: FilterCategory) {
        guard category.id != selectedTrendingCategory.id else { return }
        selectedTrendingCategory = category
        Task {
            await loadTrending(forceRefresh: true)
        }
    }

    /// Loads the full Trending list for `category`, shown by its See More screen.
    func loadTrendingDetails(
        category: FilterCategory,
        forceRefresh: Bool = false
    ) async {
        let categoryKey = category.title.uppercased()

        if !forceRefresh,
           lastTrendingDetailCategoryKey == categoryKey,
           !trendingDetailPosts.isEmpty {
            applyKnownSaveCounts()
            return
        }

        isLoadingTrendingDetails = true
        defer { isLoadingTrendingDetails = false }

        do {
            let response = try await NetworkManager.shared.getTrendingPosts(
                category: categoryKey,
                page: 1,
                limit: seeMoreLimit
            )
            trendingDetailPosts = response.posts
            lastTrendingDetailCategoryKey = categoryKey
            applyKnownSaveCounts()
        } catch {
            NetworkManager.shared.logger.error("Failed to load trending details: \(error)")
            trendingDetailPosts = []
        }
    }

    // MARK: - Private Methods

    private func overlayKnownSaveCounts(_ savedIDs: Set<String>, on posts: [Post]) -> [Post] {
        posts.map { $0.ensuringMinimumSaves(savedIDs.contains($0.id) ? 1 : 0) }
    }
}
