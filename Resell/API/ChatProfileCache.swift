//
//  ChatProfileCache.swift
//  Resell
//
//  Created by Andrew Gao on 4/22/26.
//
//  Session-scoped in-memory cache for User and Post lookups used while
//  building Chat objects. Coalesces concurrent fetches for the same id so
//  many chats sharing a buyer/seller/post only hit the network once.
//

import Foundation
import os

actor ChatProfileCache {

    // MARK: - Singleton

    static let shared = ChatProfileCache()

    // MARK: - Properties

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.cornellappdev.Resell",
        category: "ChatProfileCache"
    )

    private var users: [String: User] = [:]
    private var posts: [String: Post?] = [:]

    // In-flight tasks so concurrent callers asking for the same id share one network request.
    private var userTasks: [String: Task<User, Error>] = [:]
    private var postTasks: [String: Task<Post?, Error>] = [:]

    // MARK: - Init

    private init() {
        NotificationCenter.default.addObserver(
            forName: Constants.Notifications.LogoutUser,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            Task { await self.clear() }
        }
    }

    // MARK: - API

    /// Seed/overwrite a user in the cache without a network call. Useful for the
    /// current user, which we already have in memory via `GoogleAuthManager`.
    func setUser(_ user: User) {
        users[user.firebaseUid] = user
    }

    /// Resolve a user by id, hitting the network only on cache miss.
    func user(id: String) async throws -> User {
        if let cached = users[id] {
            return cached
        }
        if let inFlight = userTasks[id] {
            return try await inFlight.value
        }

        let task = Task<User, Error> {
            let response = try await NetworkManager.shared.getUserByID(id: id)
            return response.user
        }
        userTasks[id] = task

        defer { userTasks[id] = nil }

        do {
            let user = try await task.value
            users[id] = user
            return user
        } catch {
            logger.error("Failed to fetch user \(id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    /// Resolve a post by id, hitting the network only on cache miss.
    /// Returns `nil` if the post does not exist on the backend.
    func post(id: String) async throws -> Post? {
        if let cached = posts[id] {
            return cached
        }
        if let inFlight = postTasks[id] {
            return try await inFlight.value
        }

        let task = Task<Post?, Error> {
            let response = try await NetworkManager.shared.getPostByID(id: id)
            return response.post
        }
        postTasks[id] = task

        defer { postTasks[id] = nil }

        do {
            let post = try await task.value
            posts[id] = post
            return post
        } catch {
            logger.error("Failed to fetch post \(id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    /// Drop everything. Called on logout.
    func clear() {
        users.removeAll()
        posts.removeAll()
        userTasks.values.forEach { $0.cancel() }
        postTasks.values.forEach { $0.cancel() }
        userTasks.removeAll()
        postTasks.removeAll()
    }
}
