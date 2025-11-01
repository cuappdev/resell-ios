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
    @Published var selectedTab: Tab = .listing
    
    // For external users only
    @Published var isLoadingExternalUser: Bool = false
    @Published var externalUser: User? = nil
    @Published var externalUserPosts: [Post] = []

    enum Tab: String {
        case listing, archive, wishlist
    }
    
    // MARK: - Computed Properties
    
    var isViewingCurrentUser: Bool {
        externalUser == nil
    }
    
    var selectedPosts: [Post] {
        if isViewingCurrentUser {
            return selectedTab == .listing
                ? CurrentUserProfileManager.shared.userPosts
                : CurrentUserProfileManager.shared.archivedPosts
        } else {
            return externalUserPosts
        }
    }
    
    var requests: [Request] {
        CurrentUserProfileManager.shared.requests
    }
    
    var isLoading: Bool {
        isViewingCurrentUser
            ? CurrentUserProfileManager.shared.isLoading
            : isLoadingExternalUser
    }

    // MARK: - Functions

    func loadCurrentUser(forceRefresh: Bool = false) {
        CurrentUserProfileManager.shared.loadProfile(forceRefresh: forceRefresh)
    }
    
    func loadExternalUser(id: String) {
        // Reset external user state
        externalUser = nil
        externalUserPosts = []
        
        Task {
            isLoadingExternalUser = true
            defer { isLoadingExternalUser = false }

            do {
                externalUser = try await NetworkManager.shared.getUserByID(id: id).user
                checkUserIsBlocked(userId: id)
                externalUserPosts = try await NetworkManager.shared.getPostsByUserID(id: externalUser?.firebaseUid ?? "").posts
            } catch {
                NetworkManager.shared.logger.error("Error in ProfileViewModel.loadExternalUser: \(error)")
            }
        }
    }

    func checkUserIsBlocked(userId: String) {
        Task {
            do {
                if let currentUserId = GoogleAuthManager.shared.user?.firebaseUid {
                    let blockedUsers = try await NetworkManager.shared.getBlockedUsers(id: currentUserId).users.map { $0.firebaseUid }
                    sellerIsBlocked = blockedUsers.contains(userId)
                }
            } catch {
                NetworkManager.shared.logger.error("Error in \(#file) \(#function): \(error)")
            }
        }
    }

    func blockUser(id: String) async throws {
        let blocked = BlockUserBody(blocked: id)
        try await NetworkManager.shared.blockUser(blocked: blocked)
        sellerIsBlocked = true
    }

    func unblockUser(id: String) async throws {
        let unblocked = UnblockUserBody(unblocked: id)
        try await NetworkManager.shared.unblockUser(unblocked: unblocked)
        sellerIsBlocked = false
    }

    func deleteRequest(id: String) {
        Task {
            do {
                try await CurrentUserProfileManager.shared.deleteRequest(id: id)
            } catch {
                NetworkManager.shared.logger.error("Error in ProfileViewModel.deleteRequest: \(error)")
            }
        }
    }
}
