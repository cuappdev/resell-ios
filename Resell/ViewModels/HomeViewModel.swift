//
//  HomeViewModel.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {

    // MARK: - Shared Instance

    static let shared = HomeViewModel()

    // MARK: - Properties

    @Published var isLoading: Bool = false

    @Published var filteredItems: [Post] = []
    @Published var selectedFilter: String = "Recent" {
        didSet {
            if selectedFilter == "Recent" {
                filteredItems = allItems
            } else {
                filterPosts(by: selectedFilter)
            }
        }
    }

    @Published var savedItems: [Post] = []

    private var allItems: [Post] = []

    // MARK: - Persistent Storage

    @AppStorage("blockedUsers") private var blockedUsersStorage: String = "[]"

    // MARK: - Functions

    func getAllPosts() {
        isLoading = true

        Task {
            defer { Task { @MainActor in withAnimation { isLoading = false } } }
            
            do {
                let postsResponse = try await NetworkManager.shared.getAllPosts()
                allItems = Post.sortPostsByDate(postsResponse.posts)
                if selectedFilter == "Recent" {
                    filteredItems = allItems
                } else {
                    filterPosts(by: selectedFilter)
                }
            } catch {
                NetworkManager.shared.logger.error("Error in HomeViewModel.getAllPosts: \(error)")
            }
        }
    }

    func getSavedPosts() {
        isLoading = true

        Task {
            defer { Task { @MainActor in withAnimation { isLoading = false } } }

            do {
                let postsResponse = try await NetworkManager.shared.getSavedPosts()
                savedItems = Post.sortPostsByDate(postsResponse.posts)
            } catch {
                NetworkManager.shared.logger.error("Error in HomeViewModel.getSavedPosts: \(error)")
            }
        }
    }
    // TODO: We need support for multiple filters
    func filterPosts(by filter: String) {
        Task {
            do {
                let postsResponse = try await NetworkManager.shared.getFilteredPosts(by: selectedFilter)
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
                NetworkManager.shared.logger.error("Error in \(#file) \(#function): \(error.localizedDescription)")
            }
        }
    }

}
