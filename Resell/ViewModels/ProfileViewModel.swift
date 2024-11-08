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

    @Published var requests: [Request] = []
    @Published var selectedPosts: [Post] = []
    @Published var selectedTab: Tab = .listing
    @Published var user: User? = nil

    private var archivedPosts: [Post] = []
    private var userPosts: [Post] = []

    enum Tab: String {
        case listing, archive, wishlist
    }

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
                } else if let googleId = UserSessionManager.shared.googleID {
                    user = try await NetworkManager.shared.getUserByGoogleID(googleID: googleId).user

                    let postsResponse = try await NetworkManager.shared.getPostsByUserID(id: user?.id ?? "")
                    let archivedResponse = try await NetworkManager.shared.getArchivedPostsByUserID(id: user?.id ?? "")
                    let requestsResponse = try await NetworkManager.shared.getRequestsByUserID(id: user?.id ?? "")

                    userPosts = Post.sortPostsByDate(postsResponse.posts)
                    archivedPosts = Post.sortPostsByDate(archivedResponse.posts)
                    requests = requestsResponse.requests
                    selectedPosts = userPosts
                } else {
                    UserSessionManager.shared.logger.error("Error in ProfileViewModel.getUser: No userID or googleID found in UserSessionManager")
                }
            } catch {
                NetworkManager.shared.logger.error("Error in ProfileViewModel.getUser: \(error)")
            }
        }
    }
}
