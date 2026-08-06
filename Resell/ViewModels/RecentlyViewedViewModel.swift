//
//  RecentlyViewedViewModel.swift
//  Resell
//

import SwiftUI

@MainActor
final class RecentlyViewedViewModel: ObservableObject {

    static let shared = RecentlyViewedViewModel()

    @Published private(set) var posts: [Post] = []
    @Published private(set) var isLoading: Bool = false

    @AppStorage("recentlyViewedPostIds") private var storedIdsData: String = "[]"

    private var lastFetchTime: Date?
    private let cacheValidityDuration: TimeInterval = 180
    private let maxStoredIds = 40
    private let previewLimit = 4

    private var recentlyViewedIds: [String] {
        get {
            guard let data = storedIdsData.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let string = String(data: data, encoding: .utf8) {
                storedIdsData = string
                objectWillChange.send()
            }
        }
    }

    private init() {}

    /// Record a post view. Most-recent first; duplicates move to front.
    func recordView(postId: String) {
        var ids = recentlyViewedIds
        ids.removeAll { $0 == postId }
        ids.insert(postId, at: 0)
        if ids.count > maxStoredIds {
            ids = Array(ids.prefix(maxStoredIds))
        }
        recentlyViewedIds = ids
        lastFetchTime = nil
    }

    /// Loads up to `previewLimit` posts for the Explore collage.
    func loadPreviewPosts(forceRefresh: Bool = false) async {
        await loadPosts(limit: previewLimit, forceRefresh: forceRefresh)
    }

    /// Loads all recently viewed posts (capped by stored ids).
    func loadAllPosts(forceRefresh: Bool = false) async {
        await loadPosts(limit: maxStoredIds, forceRefresh: forceRefresh)
    }

    private func loadPosts(limit: Int, forceRefresh: Bool) async {
        let ids = Array(recentlyViewedIds.prefix(limit))
        guard !ids.isEmpty else {
            posts = []
            return
        }

        if !forceRefresh,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheValidityDuration,
           !posts.isEmpty,
           posts.count >= min(ids.count, limit) {
            return
        }

        isLoading = true
        defer { isLoading = false }

        let fetched: [Post]
        if limit == previewLimit {
            fetched = await withTaskGroup(of: (Int, Post?).self) { group in
                for (index, id) in ids.enumerated() {
                    group.addTask {
                        let response = try? await NetworkManager.shared.getPostByID(id: id)
                        return (index, response?.post)
                    }
                }

                var indexedPosts: [(Int, Post)] = []
                for await (index, post) in group {
                    if let post {
                        indexedPosts.append((index, post))
                    }
                }
                return indexedPosts
                    .sorted { $0.0 < $1.0 }
                    .map(\.1)
            }
        } else {
            var allPosts: [Post] = []
            for id in ids {
                if let response = try? await NetworkManager.shared.getPostByID(id: id),
                   let post = response.post {
                    allPosts.append(post)
                }
            }
            fetched = allPosts
        }

        posts = fetched
        lastFetchTime = Date()
    }
}
