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

    // MARK: - Functions

    func getAllPosts() {
        Task {
            do {
                let postsResponse = try await NetworkManager.shared.getAllPosts()
                allItems = postsResponse.posts

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

}
