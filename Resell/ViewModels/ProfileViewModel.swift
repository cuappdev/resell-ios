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

    @Published var selectedTab: Tab = .listing
    @Published var user: User? = nil
    @Published var selectedPosts: [Post] = []

    private var archivedPosts: [Post] = []
    private var userPosts: [Post] = []

    enum Tab: String {
        case listing, archive, wishlist
    }

    // MARK: - Functions

    func updateItemsGallery() {
        // TODO: Implement Filtering for Profile Tabs
        switch selectedTab {
        case .listing:
            selectedPosts = userPosts
            return
        case .archive:
            selectedPosts = archivedPosts
            return
        case .wishlist:
            print("Wish")
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

                    userPosts = Post.sortPostsByDate(postsResponse.posts)
                    archivedPosts = Post.sortPostsByDate(archivedResponse.posts)
                    selectedPosts = userPosts
                } else if let googleId = UserSessionManager.shared.googleID {
                    user = try await NetworkManager.shared.getUserByGoogleID(googleID: googleId).user

                    let postsResponse = try await NetworkManager.shared.getPostsByUserID(id: user?.id ?? "")
                    let archivedResponse = try await NetworkManager.shared.getArchivedPostsByUserID(id: user?.id ?? "")

                    userPosts = Post.sortPostsByDate(postsResponse.posts)
                    archivedPosts = Post.sortPostsByDate(archivedResponse.posts)
                    selectedPosts = userPosts
                } else {
                    UserSessionManager.shared.logger.error("Error in ProfileViewModel.getUser: No userID or googleID found in UserSessionManager")
                }
            } catch {
                NetworkManager.shared.logger.error("Error in ProfileViewModel.getUser: \(error.localizedDescription)")
            }

        }

    }

}
