////
////  HomeViewModel.swift
////  Resell
////
////  Created by Richie Sun on 9/12/24.
////
//
//import SwiftUI
//
//@MainActor
//class HomeViewModel: ObservableObject {
//
//    // MARK: - Properties
//    private var mainViewModel: MainViewModel?
//    
//    static let shared = HomeViewModel()
//    
//    private var searchViewModel = SearchViewModel.shared
//
//    private init() { }
//
//    func configure(mainViewModel: MainViewModel) {
//        self.mainViewModel = mainViewModel
//    }
//
//    @Published var isLoading: Bool = false
//    @Published var filteredItems: [Post] = []
//    @Published var cardsLoaded: Bool = false
//    @Published var selectedFilter: [String] = ["Recent"] {
//        didSet {
//            if selectedFilter == ["Recent"] {
//                filteredItems = allItems
//            } else {
//                filterPosts()
//            }
//        }
//    }
//    
//    @Published var savedItems: [Post] = []
//
//    private var allItems: [Post] = []
//    private var page = 1
//
//    // MARK: - Persistent Storage
//
//    @AppStorage("blockedUsers") private var blockedUsersStorage: String = "[]"
//
//    // MARK: - Functions
//
//    func getAllPosts() {
//        isLoading = true
//        Task {
//            do {
//                let postsResponse = try await NetworkManager.shared.getAllPosts()
//                allItems = Post.sortPostsByDate(postsResponse.posts)
//                // TODO: Refactor :( ...
//                if selectedFilter == ["Recent"] {
//                    filteredItems = allItems
//                } else {
//                    filterPosts()
//                }
//                isLoading = false
//            } catch {
//                // TODO: Add proper error handling
//                NetworkManager.shared.logger.error("Error in HomeViewModel.getAllPosts: \(error)")
//                isLoading = false
//            }
//        }
//    }
//
//    func fetchMoreItems() {
//        
//        print("This is being called to fetch more items")
//        
//        page += 1
//        Task {
//            do {
//                let postsResponse = try await NetworkManager.shared.getAllPosts(page: page)
//                allItems.append(contentsOf: Post.sortPostsByDate(postsResponse.posts))
//                filteredItems.append(contentsOf: Post.sortPostsByDate(postsResponse.posts))
//
//            } catch {
//                NetworkManager.shared.logger.error("Error in HomeViewModel.fetchMoreItems: \(error)")
//            }
//        }
//    }
//
//    func getSavedPosts(completion: @escaping () -> Void)  {
//        isLoading = true
//
//        Task {
//            defer { Task { @MainActor in withAnimation { isLoading = false } } }
//
//            do {
//                let postsResponse = try await NetworkManager.shared.getSavedPosts()
//                savedItems = Post.sortPostsByDate(postsResponse.posts)
//                completion()
//            } catch {
//                NetworkManager.shared.logger.error("Error in HomeViewModel.getSavedPosts: \(error)")
//            }
//        }
//    }
//    
//    // TODO: Use Unified Endpoint...
//    func filterPosts() {
//        Task {
//            do {
//                let postsResponse = try await NetworkManager.shared.getFilteredPostsByCategory(for: selectedFilter)
//                filteredItems = postsResponse.posts
//            } catch {
//                NetworkManager.shared.logger.error("Error in HomeViewModel.filterPosts: \(error)")
//            }
//            await MainActor.run {
//                isLoading = false
//            }
//        }
//    }
//
//    func getBlockedUsers() {
//        Task {
//            do {
//                if let userID = GoogleAuthManager.shared.user?.firebaseUid {
//                    let blockedUsers = try await NetworkManager.shared.getBlockedUsers(id: userID).users.map { $0.firebaseUid }
//                    if let jsonData = try? JSONEncoder().encode(blockedUsers),
//                       let jsonString = String(data: jsonData, encoding: .utf8) {
//                        blockedUsersStorage = jsonString
//                    }
//                } else {
//                    GoogleAuthManager.shared.logger.error("Error in \(#file) \(#function): User id not available.")
//                }
//
//            } catch {
//                NetworkManager.shared.logger.error("Error in \(#file) \(#function): \(error)")
//            }
//        }
//    }
//    
//    // TODO: Add function that populates recently searched
//    func getRecentlySearched(completion: @escaping () -> Void) -> Void  {
//        guard let mainVM = mainViewModel else {
//            print("Dependencies not configured")
//            return
//        }
//        
//        let group = DispatchGroup()
//            // MARK: Prefetches all search items, maybe not that efficient?
//            for searchHistoryItem in mainVM.searchHistory {
//                group.enter()
//                // TODO: Update calling this to have mappings to posts for up to 5 recently searched queries
//                searchViewModel.searchItems(with: searchHistoryItem, userID: nil, saveQuery: false, mainViewModel: mainViewModel) {
//                    group.leave()
//                }
//            }
//            
//            group.notify(queue: .main) {
//                completion()
//            }
//    }
//}

//
//  HomeViewModel.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {

    // MARK: - Properties
    private var mainViewModel: MainViewModel?
    
    static let shared = HomeViewModel()
    
    private var searchViewModel = SearchViewModel.shared

    private init() { }

    func configure(mainViewModel: MainViewModel) {
        self.mainViewModel = mainViewModel
    }

    @Published var isLoading: Bool = false
    @Published var filteredItems: [Post] = []
    @Published var cardsLoaded: Bool = false
    @Published var selectedFilter: [String] = ["Recent"] {
        didSet {
            if selectedFilter == ["Recent"] {
                filteredItems = allItems
            } else {
                filterPosts()
            }
        }
    }
    
    @Published var savedItems: [Post] = []

    private var allItems: [Post] = []
    private var page = 1
    private var hasMorePages = true
    private var isFetchingMore = false
    
    // MARK: - Caching Properties
    private var hasLoadedInitialData = false
    private var lastFetchTime: Date?
    private let cacheValidityDuration: TimeInterval = 180 // 3 minutes for home feed

    // MARK: - Persistent Storage

    @AppStorage("blockedUsers") private var blockedUsersStorage: String = "[]"

    // MARK: - Functions

    func getAllPosts(forceRefresh: Bool = false) {
        // Use cached data if available and valid
        if !forceRefresh && shouldUseCachedData() {
            print("Using cached posts data")
            return
        }
        
        isLoading = true
        page = 1
        hasMorePages = true
        
        Task {
            defer {
                Task { @MainActor in
                    withAnimation { isLoading = false }
                }
            }
            
            do {
                let postsResponse = try await NetworkManager.shared.getAllPosts()
                
                allItems = Post.sortPostsByDate(postsResponse.posts)
                filteredItems = allItems
            } catch {
                NetworkManager.shared.logger.error("Error in HomeViewModel.getAllPosts: \(error)")
            }
        }
    }

    func fetchMoreItems() {
        // Prevent multiple simultaneous fetches
        guard !isFetchingMore && hasMorePages && !isLoading else {
            print("Skipping fetch: isFetchingMore=\(isFetchingMore), hasMorePages=\(hasMorePages), isLoading=\(isLoading)")
            return
        }
        
        print("Fetching more items - page \(page + 1)")
        
        isFetchingMore = true
        page += 1
        
        Task {
            defer {
                Task { @MainActor in
                    isFetchingMore = false
                }
            }
            
            do {
                let postsResponse = try await NetworkManager.shared.getAllPosts(page: page)
                let newPosts = Post.sortPostsByDate(postsResponse.posts)
                
                // Check if we got any posts
                if newPosts.isEmpty {
                    hasMorePages = false
                    print("No more posts available")
                    return
                }
                
                // Append new posts to existing ones
                allItems.append(contentsOf: newPosts)
                
                // Only update filtered items if showing Recent
                if selectedFilter == ["Recent"] {
                    filteredItems.append(contentsOf: newPosts)
                }
                
                print("Loaded \(newPosts.count) more posts. Total: \(allItems.count)")

            } catch {
                NetworkManager.shared.logger.error("Error in HomeViewModel.fetchMoreItems: \(error)")
                page -= 1 // Revert page increment on error
            }
        }
    }

    func getSavedPosts(completion: @escaping () -> Void)  {
        isLoading = true

        Task {
            defer { Task { @MainActor in withAnimation { isLoading = false } } }

            do {
                let postsResponse = try await NetworkManager.shared.getSavedPosts()
                savedItems = Post.sortPostsByDate(postsResponse.posts)
                completion()
            } catch {
                NetworkManager.shared.logger.error("Error in HomeViewModel.getSavedPosts: \(error)")
            }
        }
    }
    
    func filterPosts() {
        Task {
            isLoading = true
            
            defer {
                Task { @MainActor in
                    isLoading = false
                }
            }
            
            do {
                let postsResponse = try await NetworkManager.shared.getFilteredPostsByCategory(for: selectedFilter)
                filteredItems = postsResponse.posts
            } catch {
                NetworkManager.shared.logger.error("Error in HomeViewModel.filterPosts: \(error)")
            }
        }
    }

    func getBlockedUsers() {
        Task {
            do {
                if let userID = GoogleAuthManager.shared.user?.firebaseUid {
                    let blockedUsers = try await NetworkManager.shared.getBlockedUsers(id: userID).users.map { $0.firebaseUid }
                    if let jsonData = try? JSONEncoder().encode(blockedUsers),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        blockedUsersStorage = jsonString
                    }
                } else {
                    GoogleAuthManager.shared.logger.error("Error in \(#file) \(#function): User id not available.")
                }

            } catch {
                NetworkManager.shared.logger.error("Error in \(#file) \(#function): \(error)")
            }
        }
    }
    
    func clearCache() {
        hasLoadedInitialData = false
        lastFetchTime = nil
        allItems = []
        filteredItems = []
        page = 1
        hasMorePages = true
    }
    
    // MARK: - Private Methods
    
    private func shouldUseCachedData() -> Bool {
        guard hasLoadedInitialData else { return false }
        guard let lastFetch = lastFetchTime else { return false }
        
        let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
        return timeSinceLastFetch < cacheValidityDuration && !allItems.isEmpty
    }
    
    // TODO: Add function that populates recently searched
    func getRecentlySearched(completion: @escaping () -> Void) -> Void  {
        guard let mainVM = mainViewModel else {
            print("Dependencies not configured")
            return
        }
        
        let group = DispatchGroup()
            // MARK: Prefetches all search items, maybe not that efficient?
            for searchHistoryItem in mainVM.searchHistory {
                group.enter()
                // TODO: Update calling this to have mappings to posts for up to 5 recently searched queries
                searchViewModel.searchItems(with: searchHistoryItem, userID: nil, saveQuery: false, mainViewModel: mainViewModel) {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                completion()
            }
    }
}
