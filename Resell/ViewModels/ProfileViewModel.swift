//
//  ProfileViewModel.swift
//  Resell
//
//  Created by Richie Sun on 9/23/24.
//

import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {

    // MARK: - Properties

    @Published var didShowOptionsMenu: Bool = false
    @Published var didShowBlockView: Bool = false
    @Published var sellerIsBlocked: Bool = false

    @Published var isLoading: Bool = false

    @Published var requests: [Request] = []
    @Published var selectedPosts: [Post] = []
    @Published var selectedTab: Tab = .listing
    @Published var user: User? = nil

    private var archivedPosts: [Post] = []
    private var userPosts: [Post] = []

    enum Tab: String {
        case listing, archive, wishlist
    }

    // MARK: - Persistent Storage

    @AppStorage("blockedUsers") private var blockedUsersStorage: String = "[]"

    // MARK: - Functions

    func updateItemsGallery() {
        switch selectedTab {
        case .listing:
            selectedPosts = userPosts
            return
        case .archive:
            selectedPosts = archivedPosts
            return
        case .wishlist:
            return
        }
    }

    func getUser() {
        Task {
            isLoading = true

            do {
                if let id = UserSessionManager.shared.userID {
                    user = try await NetworkManager.shared.getUserByID(id: id).user

                    let postsResponse = try await NetworkManager.shared.getPostsByUserID(id: id)
                    let archivedResponse = try await NetworkManager.shared.getArchivedPostsByUserID(id: id)
                    let requestsResponse = try await NetworkManager.shared.getRequestsByUserID(id: id)

                    userPosts = Post.sortPostsByDate(postsResponse.posts)
                    archivedPosts = Post.sortPostsByDate(archivedResponse.posts)
                    requests = requestsResponse.requests
                    selectedPosts = userPosts

                    withAnimation { isLoading = false }
                } else if let googleId = UserSessionManager.shared.googleID {
                    user = try await NetworkManager.shared.getUserByGoogleID(googleID: googleId).user

                    let postsResponse = try await NetworkManager.shared.getPostsByUserID(id: user?.id ?? "")
                    let archivedResponse = try await NetworkManager.shared.getArchivedPostsByUserID(id: user?.id ?? "")
                    let requestsResponse = try await NetworkManager.shared.getRequestsByUserID(id: user?.id ?? "")

                    userPosts = Post.sortPostsByDate(postsResponse.posts)
                    archivedPosts = Post.sortPostsByDate(archivedResponse.posts)
                    requests = requestsResponse.requests
                    selectedPosts = userPosts

                    withAnimation { isLoading = false }
                } else {
                    UserSessionManager.shared.logger.error("Error in ProfileViewModel.getUser: No userID or googleID found in UserSessionManager")
                    withAnimation { isLoading = false }
                }

            } catch {
                NetworkManager.shared.logger.error("Error in ProfileViewModel.getUser: \(error)")
                withAnimation { isLoading = false }
            }
        }
    }

    func getExternalUser(id: String) {
        Task {
            do {
                user = try await NetworkManager.shared.getUserByID(id: id).user
                checkUserIsBlocked()
                selectedPosts = try await NetworkManager.shared.getPostsByUserID(id: user?.id ?? "").posts
            } catch {
                NetworkManager.shared.logger.error("Error in ProfileViewModel: \(error.localizedDescription)")
            }

        }
    }

    func checkUserIsBlocked() {
        if let jsonData = $blockedUsersStorage.wrappedValue.data(using: .utf8),
           let savedBlockedUsers = try? JSONDecoder().decode([String].self, from: jsonData) {
            withAnimation {
                sellerIsBlocked = savedBlockedUsers.contains(user?.id ?? "")
            }
        }
    }

    func blockUser(id: String) {
        Task {
            isLoading = true

            do {
                let blocked = BlockUser(blocked: id)
                try await NetworkManager.shared.blockUser(blocked: blocked)

                isLoading = false
            } catch {
                NetworkManager.shared.logger.error("Error in ProfileViewModel.blockUser: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }

    func deleteRequest(id: String) {
        Task {
            do {
                try await NetworkManager.shared.deleteRequest(id: id)
            } catch {
                NetworkManager.shared.logger.error("Error in ProfileViewModel.deleteRequest: \(error)")
            }
        }
    }
}
