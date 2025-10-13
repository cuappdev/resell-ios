//
//  CurrentUserProfileManager.swift
//  Resell
//
//  Created by Charles Liggins on 10/13/25.
//

import SwiftUI

@MainActor
class CurrentUserProfileManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = CurrentUserProfileManager()
    
    // MARK: - Published Properties
    
    @Published var profilePic: UIImage = UIImage(named: "emptyProfile")!
    @Published var username: String = ""
    @Published var givenName: String = ""
    @Published var bio: String = ""
    @Published var venmoHandle: String = ""
    
    @Published var userPosts: [Post] = []
    @Published var archivedPosts: [Post] = []
    @Published var requests: [Request] = []
    
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    
    private var hasLoadedData: Bool = false
    private var lastFetchTime: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    // MARK: - Public Methods
    
    func loadProfile(forceRefresh: Bool = false) {
        // Check if we should use cached data
        if !forceRefresh && hasLoadedData && shouldUseCachedData() {
            return
        }
        
        isLoading = true
        
        Task {
            defer {
                Task { @MainActor in
                    withAnimation { isLoading = false }
                }
            }
            
            do {
                // Refresh auth if needed
                try await GoogleAuthManager.shared.refreshSignInIfNeeded()
                
                guard let user = GoogleAuthManager.shared.user else {
                    GoogleAuthManager.shared.logger.error("Error in \(#file) \(#function): User not available.")
                    return
                }
                
                let userId = user.firebaseUid
                
                // Fetch all data concurrently
                async let postsResponse = NetworkManager.shared.getPostsByUserID(id: userId)
                async let archivedResponse = NetworkManager.shared.getArchivedPostsByUserID(id: userId)
                async let requestsResponse = NetworkManager.shared.getRequestsByUserID(id: userId)
                
                let (posts, archived, reqs) = try await (postsResponse, archivedResponse, requestsResponse)
                
                // Update properties
                userPosts = Post.sortPostsByDate(posts.posts)
                archivedPosts = Post.sortPostsByDate(archived.posts)
                requests = reqs.requests
                
                username = user.username
                givenName = user.givenName
                bio = user.bio
                venmoHandle = user.venmoHandle ?? ""
                
                await decodeProfileImage(url: user.photoUrl)
                
                // Mark as loaded
                hasLoadedData = true
                lastFetchTime = Date()
                
            } catch {
                NetworkManager.shared.logger.error("Error in \(#file) \(#function): \(error)")
            }
        }
    }
    
    func updateProfile(username: String, bio: String, venmoHandle: String, profileImage: UIImage) async throws {
        isLoading = true
        
        defer {
            Task { @MainActor in
                withAnimation { isLoading = false }
            }
        }
        
        let edit = EditUserBody(
            username: username,
            bio: bio,
            venmoHandle: venmoHandle,
            photoUrlBase64: profileImage.resizedToMaxDimension(256).toBase64() ?? ""
        )
        
        let _ = try await NetworkManager.shared.updateUserProfile(edit: edit)
        
        // Update local cache
        self.username = username
        self.bio = bio
        self.venmoHandle = venmoHandle
        self.profilePic = profileImage
        
        // Refresh full profile to get any server-side changes
        await refreshProfile()
    }
    
    func deleteRequest(id: String) async throws {
        try await NetworkManager.shared.deleteRequest(id: id)
        
        // Update local cache
        requests.removeAll { $0.id == id }
    }
    
    func clearCache() {
        hasLoadedData = false
        lastFetchTime = nil
        userPosts = []
        archivedPosts = []
        requests = []
    }
    
    // MARK: - Private Methods
    
    private func shouldUseCachedData() -> Bool {
        guard let lastFetch = lastFetchTime else { return false }
        return Date().timeIntervalSince(lastFetch) < cacheValidityDuration
    }
    
    private func refreshProfile() async {
        // Force refresh without showing loading
        let wasLoading = isLoading
        await loadProfile(forceRefresh: true)
        if !wasLoading {
            isLoading = false
        }
    }
    
    private func decodeProfileImage(url: URL?) async {
        guard let url,
              let data = try? await URLSession.shared.data(from: url).0,
              let image = UIImage(data: data) else { return }
        
        profilePic = image
    }
}
