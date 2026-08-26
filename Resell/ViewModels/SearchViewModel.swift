//
//  SearchViewModel.swift
//  Resell
//
//  Created by Charles Liggins on 9/12/25.
//

import SwiftUI

@MainActor
class SearchViewModel: ObservableObject {
        @Published var searchedItems: [Post] = []
        @Published var isLoading: Bool = false
        @Published var isSearching: Bool = true
        
        @AppStorage("recentlySearched") private var recentlySearchedStorage: String = "[]"
        
        // ✅ Computed property that reads/writes to AppStorage directly
        var recentlySearched: [String] {
            get {
                if let jsonData = recentlySearchedStorage.data(using: .utf8),
                   let decoded = try? JSONDecoder().decode([String].self, from: jsonData) {
                    return decoded
                }
                return []
            }
            set {
                if let jsonData = try? JSONEncoder().encode(newValue),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    recentlySearchedStorage = jsonString
                    // Manually trigger objectWillChange since this isn't @Published
                    objectWillChange.send()
                }
            }
        }
        
        static let shared = SearchViewModel()
    
    private var cachedRecentlySearchedPosts: [Post] = []
    private var lastRecentlySearchedFetchTime: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    
    func searchItems(with searchText: String, userID: String?, saveQuery: Bool = false, mainViewModel: MainViewModel? = nil, completion: @escaping () -> Void) {
        guard !searchText.isEmpty else {
            searchedItems = []
            return
        }
        
        isSearching = false
        isLoading = true
        
        Task {
            defer { Task { @MainActor in
                withAnimation { isLoading = false }
                completion()
            }
            }
            
            do {
                let postsResponse = try await NetworkManager.shared.getSearchedPosts(with: searchText)
                
                if !recentlySearched.contains(postsResponse.searchId) {
                    recentlySearched.insert(postsResponse.searchId, at: 0)
                    // Keep only last 5 searches
                    if recentlySearched.count > 5 {
                        recentlySearched = Array(recentlySearched.prefix(5))
                    }
                }
                
                // Filter or set searchedItems based on userID
                if let userID = userID {
                    searchedItems = postsResponse.posts.filter { $0.user?.firebaseUid == userID }
                } else {
                    searchedItems = postsResponse.posts
                }
                                
                if saveQuery {
                    await MainActor.run {
                        mainViewModel?.saveSearchQuery(searchText)
                    }
                }
            } catch {
                NetworkManager.shared.logger.error("Error in SearchViewModel.searchItems: \(error.localizedDescription)")
            }
        }
    }
    
    /// Fetch posts for a specific searchId (for displaying in ForYou card)
    func fetchPostsForSearchId(_ searchId: String, limit: Int = 4) async -> [Post] {
        do {
            let postIds = try await NetworkManager.shared.getSearchSuggestions(searchIndex: searchId)
            print("this far?")

            // Take only the number we need
            let limitedIds = Array(postIds.postIds.prefix(limit))
            
            // Fetch the actual posts by ID
            print("this far?")
            return await fetchPostsByIds(limitedIds)
            
        } catch {
            NetworkManager.shared.logger.error("Error fetching posts for searchId '\(searchId)': \(error)")
            return []
        }
    }
    
    /// Fetch multiple posts by their IDs
    /// Note: You'll need to implement this endpoint in your backend if it doesn't exist
    private func fetchPostsByIds(_ postIds: [String]) async -> [Post] {
        // If you have a bulk fetch endpoint:
        // return try? await NetworkManager.shared.getPostsByIds(postIds)
        
        // Otherwise, fetch individually (less efficient).
        var posts: [Post] = []
        for postId in postIds {
            if let response = try? await NetworkManager.shared.getPostByID(id: postId),
               let post = response.post {
                posts.append(post)
            }
        }
        return posts
    }
    
    // TODO: This is getting called way too much, in places it shouldn't be called.
    /// Load posts for recently searched card (fetch just enough to display)
    func loadRecentlySearchedPosts() async -> [Post] {
        if let lastFetch = lastRecentlySearchedFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheValidityDuration,
           !cachedRecentlySearchedPosts.isEmpty {
            print("Using cached recently searched posts")
            return cachedRecentlySearchedPosts
        }
        
        print("Called Recent Searches")
        guard !recentlySearched.isEmpty else {
            return []
        }
        
        var allPosts: [Post] = []
        var seenIds = Set<String>()
        
        // Fetch from recent searches until we have 4 unique posts
        for searchId in recentlySearched.prefix(3) {
            print("🔄 Fetching posts for searchId: \(searchId)")
            let posts = await fetchPostsForSearchId(searchId, limit: 2)
            print("✅ Got \(posts.count) posts for searchId: \(searchId)")
            
            for post in posts {
                if !seenIds.contains(post.id) {
                    allPosts.append(post)
                    seenIds.insert(post.id)
                    
                    if allPosts.count >= 4 {
                        print("✅ Loaded 4 posts, returning early")
                        let result = Array(allPosts.prefix(4))
                        cachedRecentlySearchedPosts = result
                        lastRecentlySearchedFetchTime = Date()
                        return result
                    }
                }
            }
        }
        
        print("✅ Loaded \(allPosts.count) total posts")
        cachedRecentlySearchedPosts = allPosts
        lastRecentlySearchedFetchTime = Date()
        return allPosts
    }
    
    /// Load all suggestions for SuggestionsView (up to 25 posts)
    func loadAllSuggestions() async -> [Post] {
        guard !recentlySearched.isEmpty else { return [] }
        
        var allPosts: [Post] = []
        var seenIds = Set<String>()
        
        // Take up to 5 recent searches
        for searchId in recentlySearched.prefix(5) {
            do {
                let postIds = try await NetworkManager.shared.getSearchSuggestions(searchIndex: searchId)
                
                // Take up to 5 suggestions per search
                let limitedIds = Array(postIds.postIds.prefix(5))
                let posts = await fetchPostsByIds(limitedIds)
                
                for post in posts {
                    if !seenIds.contains(post.id) {
                        allPosts.append(post)
                        seenIds.insert(post.id)
                        
                        // Stop at 25 total posts
                        if allPosts.count >= 25 {
                            return Array(allPosts.prefix(25))
                        }
                    }
                }
            } catch {
                NetworkManager.shared.logger.error("Error loading suggestions for searchId '\(searchId)': \(error)")
            }
        }
        
        return allPosts
    }
    
    func clearCache() {
        cachedRecentlySearchedPosts = []
        lastRecentlySearchedFetchTime = nil
    }
}
