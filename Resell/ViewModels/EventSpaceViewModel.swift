//
//  EventSpaceViewModel.swift
//  Resell
//
//  Created by Andrew Gao on 10/11/26.
//

import SwiftUI

/// State behind one event space's feed: the listings tagged with its event,
/// loaded a page at a time.
@MainActor
final class EventSpaceViewModel: ObservableObject {

    // MARK: - Properties

    @Published private(set) var posts: [Post] = []
    /// Starts true so the empty state doesn't flash before the first load.
    @Published private(set) var isLoading: Bool = true

    private let event: EventSpace
    private let pageSize = 20

    private var page = 1
    private var hasMorePages = true
    private var isFetchingMore = false

    init(event: EventSpace) {
        self.event = event
    }

    // MARK: - Functions

    /// Loads the first page, keeping what is already shown unless `forceRefresh` is set.
    func loadPosts(forceRefresh: Bool = false) async {
        guard forceRefresh || posts.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await NetworkManager.shared.getPostsByEventTags(
                [event.tag],
                page: 1,
                limit: pageSize
            )
            posts = response.posts
            page = 1
            hasMorePages = !response.posts.isEmpty
        } catch {
            NetworkManager.shared.logger.error("Failed to load event posts for \(self.event.tag): \(error)")
        }
    }

    /// Appends the next page; called as the feed scrolls near its end.
    func fetchMorePosts() {
        guard !isLoading, !isFetchingMore, hasMorePages else { return }

        isFetchingMore = true
        let nextPage = page + 1

        Task {
            defer { isFetchingMore = false }

            do {
                let response = try await NetworkManager.shared.getPostsByEventTags(
                    [event.tag],
                    page: nextPage,
                    limit: pageSize
                )

                // The backend drops blocked and inactive sellers after paging, so a
                // short page isn't the end; only an empty one is.
                guard !response.posts.isEmpty else {
                    hasMorePages = false
                    return
                }

                let knownIDs = Set(posts.map(\.id))
                posts.append(contentsOf: response.posts.filter { !knownIDs.contains($0.id) })
                page = nextPage
            } catch {
                NetworkManager.shared.logger.error("Failed to load more event posts for \(self.event.tag): \(error)")
            }
        }
    }
}
