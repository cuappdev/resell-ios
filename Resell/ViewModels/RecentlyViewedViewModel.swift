//
//  RecentlyViewedViewModel.swift
//  Resell
//
//  Created by Andrew Gao on 9/3/26.
//

import SwiftUI

/// The listings the user opened most recently, newest first.
///
/// Shared because `ProductDetailsViewModel` records views into it while Explore
/// and `RecentlyViewedView` read from it. The IDs and the listings themselves are
/// persisted so the list renders on launch before anything is refetched.
@MainActor
final class RecentlyViewedViewModel: ObservableObject {

    // MARK: - Properties

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
            decodeStored([String].self, from: storedIdsData) ?? []
        }
        set {
            guard let encoded = encodeForStorage(newValue) else { return }
            storedIdsData = encoded
            objectWillChange.send()
        }
    }

    private init() {
        hydrateCache()
        publishOrderedPosts()
    }

    // MARK: - Functions

    /// Record a post view, most-recent first, and cache the listing so Recently
    /// Viewed can render it without a refetch. Duplicates move to the front.
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

    /// Loads the first page for an immediate render, then the rest.
    func loadAllPosts(forceRefresh: Bool = false) async {
        await loadPosts(limit: pageSize, forceRefresh: forceRefresh)
        // The first page is in the cache now; only the tail is still missing.
        await loadPosts(limit: maxStoredIds, forceRefresh: false)
    }

    // MARK: - Private Methods

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
        guard let decoded = decodeStored([Post].self, from: storedPostsData) else { return }
        postCache = Dictionary(uniqueKeysWithValues: decoded.map { ($0.id, $0) })
    }

    private func persistCache() {
        let ordered = recentlyViewedIds.compactMap { postCache[$0] }
        guard let encoded = encodeForStorage(ordered) else { return }
        storedPostsData = encoded
    }

    /// Stored lists go through `NetworkManager`'s shared coders so cached posts
    /// round-trip their dates exactly as the backend's JSON does.
    private func encodeForStorage<T: Encodable>(_ value: T) -> String? {
        guard let data = try? NetworkManager.shared.jsonEncoder.encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func decodeStored<T: Decodable>(_ type: T.Type, from string: String) -> T? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? NetworkManager.shared.jsonDecoder.decode(type, from: data)
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
