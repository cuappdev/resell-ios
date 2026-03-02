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
    
    @Published var isLoadingExternalUser: Bool = false
    @Published var externalUser: User? = nil
    @Published var externalUserPosts: [Post] = []
    @Published var externalUserReviews: [UserReview] = []
    
    @Published var isFollowing: Bool = false
    @Published var isFollowLoading: Bool = false
    @Published var followerCount: Int = 0
    @Published var followingCount: Int = 0
    
    /// Computed average star rating for the external user
    var averageStarRating: Double {
        guard !externalUserReviews.isEmpty else { return 0 }
        let total = externalUserReviews.reduce(0) { $0 + $1.stars }
        return Double(total) / Double(externalUserReviews.count)
    }
    
    var reviewCount: Int {
        externalUserReviews.count
    }
    
    /// Number of items sold - uses backend value if available, otherwise falls back to review count
    var soldCount: Int {
        // If backend returns a valid soldPosts count, use it
        if let backendCount = externalUser?.soldPosts, backendCount > 0 {
            return backendCount
        }
        // Fallback: use review count since each review represents a completed transaction
        return externalUserReviews.count
    }

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
    
    var displayBio: String {
        if isViewingCurrentUser {
            return CurrentUserProfileManager.shared.bio
        } else {
            if let bio = externalUser?.bio, !bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return bio
            }
            
            let name = externalUser?.givenName ?? externalUser?.username ?? "a Cornell Student"
            return "Hi, I'm \(name)! Looking for great deals and selling even greater items."
        }
    }

    // MARK: - Functions

    func loadCurrentUser(forceRefresh: Bool = false) {
        CurrentUserProfileManager.shared.loadProfile(forceRefresh: forceRefresh)
    }
    
    func loadExternalUser(id: String) {
        externalUser = nil
        externalUserPosts = []
        externalUserReviews = []
        isFollowing = false
        followerCount = 0
        followingCount = 0
        
        Task {
            isLoadingExternalUser = true
            defer { isLoadingExternalUser = false }

            do {
                externalUser = try await NetworkManager.shared.getUserByID(id: id).user
                
                // Fetch actual follower/following counts from dedicated endpoints
                async let fetchedFollowers = NetworkManager.shared.getFollowers(id: id).users
                async let fetchedFollowing = NetworkManager.shared.getFollowing(id: id).users
                
                let followers = try await fetchedFollowers
                let following = try await fetchedFollowing
                
                followerCount = followers.count
                followingCount = following.count
                
                checkUserIsBlocked(userId: id)
                checkUserIsFollowing(userId: id)
                externalUserPosts = try await NetworkManager.shared.getPostsByUserID(id: externalUser?.firebaseUid ?? "").posts
                
                // Fetch user reviews for this seller (UserReview has buyer info directly)
                // Use firebaseUid for consistency with posts
                if let firebaseUid = externalUser?.firebaseUid {
                do {
                        externalUserReviews = try await NetworkManager.shared.getUserReviewsBySeller(sellerId: firebaseUid)
                } catch {
                        NetworkManager.shared.logger.error("Error fetching user reviews: \(error)")
                        externalUserReviews = []
                    }
                } else {
                    NetworkManager.shared.logger.error("Cannot fetch reviews: externalUser has no firebaseUid")
                    externalUserReviews = []
                }
            } catch {
                NetworkManager.shared.logger.error("Error in ProfileViewModel.loadExternalUser: \(error)")
            }
        }
    }
    
    func checkUserIsFollowing(userId: String) {
        Task {
            do {
                if let currentUserId = GoogleAuthManager.shared.user?.firebaseUid {
                    let followingUsers = try await NetworkManager.shared.getFollowing(id: currentUserId).users.map { $0.firebaseUid }
                    isFollowing = followingUsers.contains(userId)
                }
            } catch {
                NetworkManager.shared.logger.error("Error in \(#file) \(#function): \(error)")
            }
        }
    }
    
    func followUser(id: String) async throws {
        isFollowLoading = true
        defer { isFollowLoading = false }
        
        let follow = FollowUserBody(userId: id)
        _ = try await NetworkManager.shared.followUser(follow: follow)
        isFollowing = true
        followerCount += 1
    }
    
    func unfollowUser(id: String) async throws {
        isFollowLoading = true
        defer { isFollowLoading = false }
        
        let unfollow = UnfollowUserBody(userId: id)
        _ = try await NetworkManager.shared.unfollowUser(unfollow: unfollow)
        isFollowing = false
        followerCount = max(0, followerCount - 1)
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
