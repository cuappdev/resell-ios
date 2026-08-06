//
//  ExploreViewModel.swift
//  Resell
//

import SwiftUI

@MainActor
final class ExploreViewModel: ObservableObject {

    static let shared = ExploreViewModel()

    @Published private(set) var dailyPicks: [Post] = []
    @Published private(set) var trendingPosts: [Post] = []
    @Published private(set) var trendingDetailPosts: [Post] = []
    @Published private(set) var isLoadingDailyPicks: Bool = false
    @Published private(set) var isLoadingTrending: Bool = false
    @Published private(set) var isLoadingTrendingDetails: Bool = false

    /// Product categories only (excludes "Recent").
    let trendingCategories: [FilterCategory] = Constants.filters.filter { $0.color != nil }

    @Published var selectedTrendingCategory: FilterCategory = Constants.filters.first { $0.title == "Electronics" }
        ?? FilterCategory(id: 4, title: "Electronics", color: Constants.Colors.filterPink)

    private var lastDailyPicksFetch: Date?
    private var lastTrendingFetch: Date?
    private var lastTrendingCategoryKey: String?
    private var lastTrendingDetailCategoryKey: String?
    private let cacheValidityDuration: TimeInterval = 180

    private let previewLimit = 10
    private let seeMoreLimit = 40

    private init() {}

    /// API category query value matching backend seed names (`ELECTRONICS`, …).
    var trendingCategoryAPIName: String {
        selectedTrendingCategory.title.uppercased()
    }

    func loadAll(forceRefresh: Bool = false) async {
        async let picks: () = loadDailyPicks(forceRefresh: forceRefresh)
        async let trending: () = loadTrending(forceRefresh: forceRefresh)
        await picks
        await trending
    }

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

    func loadTrending(forceRefresh: Bool = false) async {
        let categoryKey = trendingCategoryAPIName

        if !forceRefresh,
           lastTrendingCategoryKey == categoryKey,
           let lastFetch = lastTrendingFetch,
           Date().timeIntervalSince(lastFetch) < cacheValidityDuration,
           !trendingPosts.isEmpty {
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
        } catch {
            NetworkManager.shared.logger.error("Failed to load trending posts: \(error)")
            trendingPosts = []
        }
    }

    func selectTrendingCategory(_ category: FilterCategory) {
        guard category.id != selectedTrendingCategory.id else { return }
        selectedTrendingCategory = category
        Task {
            await loadTrending(forceRefresh: true)
        }
    }

    func loadTrendingDetails(
        category: FilterCategory,
        forceRefresh: Bool = false
    ) async {
        let categoryKey = category.title.uppercased()

        if !forceRefresh,
           lastTrendingDetailCategoryKey == categoryKey,
           !trendingDetailPosts.isEmpty {
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
        } catch {
            NetworkManager.shared.logger.error("Failed to load trending details: \(error)")
            trendingDetailPosts = []
        }
    }
}
