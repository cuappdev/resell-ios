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

    @Published var allItems: [Item] = Constants.dummyItemsData
    @Published var selectedFilter: String = "Recent"

    @Published var savedItems: [Item] = [
        Item(id: UUID(), title: "Justin", image: "justin", price: "$100", category: "School"),
        Item(id: UUID(), title: "Justin", image: "justin_long", price: "$100", category: "School"),
        Item(id: UUID(), title: "Justin", image: "justin_long", price: "$100", category: "School")
    ]

    // MARK: - Functions

    func getAllPosts() {
        Task {
            do {
                let posts = try await NetworkManager.shared.getAllPosts()
                print(posts)
            } catch {
                NetworkManager.shared.logger.error("Error in HomeViewModel.getAllPosts: \(error)")
            }
        }
    }

}
