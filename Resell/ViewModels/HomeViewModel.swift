//
//  HomeViewModel.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import SwiftUI
import Kingfisher

@MainActor
class HomeViewModel: ObservableObject {

    // MARK: - Properties
    private var mainViewModel: MainViewModel?
    
    static let shared = HomeViewModel()
    
    private var searchViewModel = SearchViewModel.shared

    private init() {
        configureImageCache()
    }

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

    @AppStorage("blockedUsers") private var blockedUsersStorage: String = "[]"

    // MARK: - Functions
    
    private func configureImageCache() {
        let cache = ImageCache.default
        
        cache.memoryStorage.config.totalCostLimit = 150 * 1024 * 1024 // 150 MB
        
        cache.diskStorage.config.sizeLimit = 500 * 1024 * 1024 // 500 MB
        
        cache.memoryStorage.config.expiration = .seconds(600) // 10 minutes
        
        cache.diskStorage.config.expiration = .days(7)
        
        ImageDownloader.default.downloadTimeout = 15.0
        KingfisherManager.shared.downloader.downloadTimeout = 15.0
        
    }

    func getAllPosts(forceRefresh: Bool = false) {
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
        guard !isFetchingMore && hasMorePages else {
            return
        }
        
        
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
                
                if newPosts.isEmpty {
                    hasMorePages = false
                    print("🛑 No more posts available")
                    return
                }
                
                allItems.append(contentsOf: newPosts)
                
                if selectedFilter == ["Recent"] {
                    filteredItems = allItems
                }
                
                print("✅ Loaded \(newPosts.count) more posts. Total posts: \(allItems.count), Memory: \(getMemoryUsage()) MB")

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
        
        ImageCache.default.clearMemoryCache()
        print("🧹 Cleared all caches")
    }
    
    func cleanupMemory() {
        ImageCache.default.clearMemoryCache()
        print("🧹 Cleaned up image memory cache")
    }
    
    // MARK: - Private Methods
    
    private func shouldUseCachedData() -> Bool {
        guard hasLoadedInitialData else { return false }
        guard let lastFetch = lastFetchTime else { return false }
        
        let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
        return timeSinceLastFetch < cacheValidityDuration && !allItems.isEmpty
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
            return usedMemory
        }
        return 0
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
