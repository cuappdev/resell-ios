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
        Task {
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
        Task {
            do {
                let postsResponse = try await NetworkManager.shared.getSavedPosts()
                savedItems = postsResponse.posts
            } catch {
                NetworkManager.shared.logger.error("Error in HomeViewModel.getSavedPosts: \(error)")
            }
        }
    }

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
                if let userID = UserSessionManager.shared.userID {
                    let blockedUsers = try await NetworkManager.shared.getBlockedUsers(id: userID).users.map { $0.id }
                    if let jsonData = try? JSONEncoder().encode(blockedUsers),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        blockedUsersStorage = jsonString
                    }
                } else {
                    UserSessionManager.shared.logger.error("Error in BlockedUsersView: userID not found.")
                }

            } catch {
                NetworkManager.shared.logger.error("Error in BlockedUsersView: \(error.localizedDescription)")
            }
        }
    }

}
