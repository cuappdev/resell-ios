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

    @Published var allItems: [Post] = []
    @Published var selectedFilter: String = "Recent"

    @Published var savedItems: [Post] = []



    // MARK: - Functions

    func getAllPosts() {
        Task {
            do {
                let posts = try await NetworkManager.shared.getAllPosts()
                allItems = posts.posts
            } catch {
                NetworkManager.shared.logger.error("Error in HomeViewModel.getAllPosts: \(error)")
            }
        }
    }

}
