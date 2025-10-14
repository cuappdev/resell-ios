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
    @Published var recentlySearched: [Post] = []
        
    static let shared = SearchViewModel()

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
                completion()  // Call completion after search finishes
                }
            }

            do {
                let postsResponse = try await NetworkManager.shared.getSearchedPosts(with: searchText)

                if let userID = userID {
                    searchedItems = postsResponse.posts.filter { $0.user?.firebaseUid == userID }
                } else {
                    if !saveQuery {
                        recentlySearched.append(contentsOf: postsResponse.posts)
                        
                    } else {
                        searchedItems = postsResponse.posts
                    }
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
}
