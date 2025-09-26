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
    @Published var selectedFilter: String = "Recent" {
        didSet {
            if selectedFilter == "Recent" {
                filteredItems = allItems
            } else {
                filterPosts()
            }
        }
    }
    
//    @Published var recentlySearched: [Post] = []
    @Published var savedItems: [Post] = []

    private var allItems: [Post] = []
    private var page = 1

    // MARK: - Persistent Storage

    @AppStorage("blockedUsers") private var blockedUsersStorage: String = "[]"

    // MARK: - Functions

    func getAllPosts() {
        isLoading = true
        Task {
            do {
                let postsResponse = try await NetworkManager.shared.getAllPosts()
                allItems = Post.sortPostsByDate(postsResponse.posts)
                if selectedFilter == "Recent" {
                    filteredItems = allItems
                } else {
                    filterPosts()
                }
                isLoading = false
            } catch {
                // TODO: Add proper error handling
                NetworkManager.shared.logger.error("Error in HomeViewModel.getAllPosts: \(error)")
                isLoading = false
            }
        }
    }

    func fetchMoreItems() {
        page += 1
        Task {
            do {
                let postsResponse = try await NetworkManager.shared.getAllPosts(page: page)
                allItems.append(contentsOf: Post.sortPostsByDate(postsResponse.posts))
                filteredItems.append(contentsOf: Post.sortPostsByDate(postsResponse.posts))

            } catch {
                NetworkManager.shared.logger.error("Error in HomeViewModel.fetchMoreItems: \(error)")
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
    
    // TODO: We need support for multiple filters
    func filterPosts() {
        Task {
            do {
                let postsResponse = try await NetworkManager.shared.getFilteredPosts(by: [selectedFilter])
                filteredItems = postsResponse.posts
            } catch {
                NetworkManager.shared.logger.error("Error in HomeViewModel.filterPosts: \(error)")
            }
            await MainActor.run {
                isLoading = false
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
    
    // TODO: Add function that populates recently searched
    func getRecentlySearched(completion: @escaping () -> Void) -> Void  {
        guard let mainVM = mainViewModel else {
            print("Dependencies not configured")
            return
        }
        
        let group = DispatchGroup()
            
            for searchHistoryItem in mainVM.searchHistory {
                group.enter()
                searchViewModel.searchItems(with: searchHistoryItem, userID: nil, saveQuery: false, mainViewModel: mainViewModel) {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                completion()
            }
    }
}
