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
    @Published var isLoadingUser: Bool = false

    @Published var requests: [Request] = []
    @Published var selectedPosts: [Post] = []
    @Published var selectedTab: Tab = .listing
    @Published var user: User? = nil
    
    @Published var profilePic: UIImage = UIImage(named: "emptyProfile")!

    // REFACTOR I HATE THIS
    @Published var username: String = ""
    @Published var bio: String = ""
    

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
        isLoading = true

        Task {
            defer { Task { @MainActor in withAnimation { isLoading = false } } }

            do {
                // why tf was this not here chat
                guard let user = GoogleAuthManager.shared.user else {
                    GoogleAuthManager.shared.logger.error("Error in \(#file) \(#function): User not available.")
                    return
                }
                
                if let userId = GoogleAuthManager.shared.user?.firebaseUid {
                    let postsResponse = try await NetworkManager.shared.getPostsByUserID(id: userId)
                    let archivedResponse = try await NetworkManager.shared.getArchivedPostsByUserID(id: userId)
                    let requestsResponse = try await NetworkManager.shared.getRequestsByUserID(id: userId)
                    
                    userPosts = Post.sortPostsByDate(postsResponse.posts)
                    print("# User Posts: \(userPosts.count)")
                    archivedPosts = Post.sortPostsByDate(archivedResponse.posts)
                    requests = requestsResponse.requests
                    selectedPosts = userPosts
                    
                    username = user.username
                    bio = user.bio
                
                    await decodeProfileImage(url: user.photoUrl)
                } else {
                    GoogleAuthManager.shared.logger.error("Error in \(#file) \(#function): User id not available.")
                }

            } catch {
                NetworkManager.shared.logger.error("Error in \(#file) \(#function): \(error)")
            }
        }
    }

    func getExternalUser(id: String) {
        Task {
            isLoadingUser = true

            do {
                user = try await NetworkManager.shared.getUserByID(id: id).user
                checkUserIsBlocked()
                selectedPosts = try await NetworkManager.shared.getPostsByUserID(id: user?.firebaseUid ?? "").posts

                isLoadingUser = false
            } catch {
                NetworkManager.shared.logger.error("Error in ProfileViewModel: \(error)")
                isLoadingUser = false
            }
        }
    }

    func checkUserIsBlocked() {
        Task {
            do {
                if let userId = GoogleAuthManager.shared.user?.firebaseUid {
                    let blockedUsers = try await NetworkManager.shared.getBlockedUsers(id: userId).users.map { $0.firebaseUid }
                    sellerIsBlocked = blockedUsers.contains(userId)
                } else {
                    GoogleAuthManager.shared.logger.error("Error in \(#file) \(#function): User id not available.")
                }
            } catch {
                NetworkManager.shared.logger.error("Error in \(#file) \(#function): \(error)")
            }
        }
    }

    func blockUser(id: String) {
        isLoading = true

        Task {
            defer { Task { @MainActor in withAnimation { isLoading = false } } }

            do {
                let blocked = BlockUserBody(blocked: id)
                try await NetworkManager.shared.blockUser(blocked: blocked)
            } catch {
                NetworkManager.shared.logger.error("Error in \(#file) \(#function): \(error)")
            }
        }
    }

    func unblockUser(id: String) {
        isLoading = true

        Task {
            defer { Task { @MainActor in withAnimation { isLoading = false } } }

            do {
                let unblocked = UnblockUserBody(unblocked: id)
                try await NetworkManager.shared.unblockUser(unblocked: unblocked)
            } catch {
                NetworkManager.shared.logger.error("Error in ProfileViewModel.unblockUser: \(error)")
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
    
    private func decodeProfileImage(url: URL?) async {
        guard let url,
              let data = try? await URLSession.shared.data(from: url).0,
              let image = UIImage(data: data) else { return }

        profilePic = image
    }
}
