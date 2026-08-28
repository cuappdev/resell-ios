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
    @AppStorage("recentlyViewedPostsCache") private var storedPostsData: String = "[]"

    private var postCache: [String: Post] = [:]
    private let maxStoredIds = 40
    private let pageSize = 10

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

    private init() {
        hydrateCache()
        publishOrderedPosts()
    }

    /// Record a post view. Most-recent first; duplicates move to front.
    func recordView(postId: String) {
        moveIdToFront(postId)
        publishOrderedPosts()
    }

    /// Cache the listing immediately so Recently Viewed doesn't refetch it.
    func recordView(post: Post) {
        postCache[post.id] = post
        moveIdToFront(post.id)
        persistCache()
        publishOrderedPosts()
    }

    /// Loads the first page so Explore + Recently Viewed can render immediately.
    func loadPreviewPosts(forceRefresh: Bool = false) async {
        await loadPosts(limit: pageSize, forceRefresh: forceRefresh)
    }

    /// Loads the first page, then the rest in the background.
    func loadAllPosts(forceRefresh: Bool = false) async {
        await loadPosts(limit: pageSize, forceRefresh: forceRefresh)
        await loadPosts(limit: maxStoredIds, forceRefresh: forceRefresh)
    }

    private func moveIdToFront(_ postId: String) {
        var ids = recentlyViewedIds
        ids.removeAll { $0 == postId }
        ids.insert(postId, at: 0)
        if ids.count > maxStoredIds {
            ids = Array(ids.prefix(maxStoredIds))
        }
        recentlyViewedIds = ids
    }

    private func loadPosts(limit: Int, forceRefresh: Bool) async {
        let ids = Array(recentlyViewedIds.prefix(limit))
        guard !ids.isEmpty else {
            posts = []
            return
        }

        publishOrderedPosts()

        let missingIds = forceRefresh ? ids : ids.filter { postCache[$0] == nil }
        guard !missingIds.isEmpty else { return }

        let shouldBlockUI = posts.isEmpty
        if shouldBlockUI { isLoading = true }
        defer { if shouldBlockUI { isLoading = false } }

        let fetched = await fetchPostsInParallel(missingIds)
        for post in fetched {
            postCache[post.id] = post
        }
        persistCache()
        publishOrderedPosts()
    }

    /// Publish every cached listing in recency order — never shrink the list
    /// just because a page load asked for 10 items.
    private func publishOrderedPosts() {
        posts = recentlyViewedIds.compactMap { postCache[$0] }
    }

    private func hydrateCache() {
        guard let data = storedPostsData.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([Post].self, from: data) else {
            return
        }
        postCache = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
    }

    private func persistCache() {
        let ordered = recentlyViewedIds.compactMap { postCache[$0] }
        guard let data = try? JSONEncoder().encode(ordered),
              let string = String(data: data, encoding: .utf8) else {
            return
        }
        storedPostsData = string
    }

    private func fetchPostsInParallel(_ ids: [String]) async -> [Post] {
        guard !ids.isEmpty else { return [] }

        return await withTaskGroup(of: (Int, Post?).self) { group in
            let maxConcurrent = 8
            var nextIndex = 0

            func enqueue() {
                guard nextIndex < ids.count else { return }
                let index = nextIndex
                let id = ids[index]
                nextIndex += 1
                group.addTask {
                    let response = try? await NetworkManager.shared.getPostByID(id: id)
                    return (index, response?.post)
                }
            }

            for _ in 0..<min(maxConcurrent, ids.count) {
                enqueue()
            }

            var indexedPosts: [(Int, Post)] = []
            for await (index, post) in group {
                if let post {
                    indexedPosts.append((index, post))
                }
                enqueue()
            }

            return indexedPosts
                .sorted { $0.0 < $1.0 }
                .map(\.1)
        }
    }
}
