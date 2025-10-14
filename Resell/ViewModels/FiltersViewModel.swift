////
////  FiltersViewModel.swift
////  Resell
////
////  Created by Charles Liggins on 9/26/25.
////
//
//import SwiftUI
//import Combine
//
//@MainActor
//class FiltersViewModel: ObservableObject {
//    @Published var categoryFilters: Set<String> = []
//    @Published var conditionFilters: Set<String> = []
//    @Published var lowValue: Double = 0
//    @Published var highValue: Double = 1000
//    @Published var showSale: Bool = false
//    @Published var selectedSort: SortOption? = nil
//    @Published var detailedFilterItems: [Post] = []
//    private var baseCategory: String? = nil // Store the base category for detailed view
//
//    func initializeDetailedFilter(category: String) async throws {
//        baseCategory = category
//        categoryFilters = [category] // Pre-populate with the category
//        try await applyFilters(homeViewModel: HomeViewModel.shared)
//    }
//        
//    let isHome: Bool
//    
//    init(isHome: Bool = false) {
//           self.isHome = isHome
//       }
//       
//    // TODO: Use Unified endpoint
//    func applyFilters(homeViewModel: HomeViewModel) async throws {
//        let categoryFiltersList = Array(categoryFilters)
//        let conditionFiltersList = Array(conditionFilters)
//
//        var sortField: String
//
//        if let selectedSort = selectedSort {
//            switch selectedSort {
//            case .any:
//                sortField = "any"
//            case .newlyListed:
//                sortField = "newlyListed"
//            case .priceHighToLow:
//                sortField = "priceHighToLow"
//            case .priceLowToHigh:
//                sortField = "priceLowToHigh"
//            }
//        } else {
//            sortField = "any"
//        }
//    
//        let priceBody = PriceBody(lowerBound: Int(lowValue), upperBound: Int(highValue))
//        let unifiedFilter = FilterPostsUnifiedRequest(
//                                sortField: sortField,
//                                price: priceBody,
//                                categories: categoryFiltersList,
//                                condition: conditionFiltersList
//                                )
//
//        
//        Task {
//            do {
//                let postsResponse = try await NetworkManager.shared.getUnifiedFilteredPosts(filters: unifiedFilter)
//                if isHome {
//                    homeViewModel.filteredItems = postsResponse.posts
//                } else {
//                    print("hello wtf1")
//
//                    detailedFilterItems = postsResponse.posts
//                }
//            } catch {
//                print("hello wtf2")
//
//                NetworkManager.shared.logger.error("Error in FiltersViewModel.applyFilters: \(error)")
//            }
//        }
//        
//    }
//    
//    func resetFilters(homeViewModel: HomeViewModel) {
//        categoryFilters.removeAll()
//        conditionFilters.removeAll()
//        lowValue = 0
//        highValue = 1000
//        showSale = false
//        selectedSort = nil
//        
//        if isHome {
//             homeViewModel.selectedFilter = ["Recent"]
//         } else if let category = baseCategory {
//             // For detailed view, reset to just the base category
//             categoryFilters = [category]
//             Task {
//                 try? await applyFilters(homeViewModel: homeViewModel)
//             }
//         }
//    }
//}

//
//  FiltersViewModel.swift
//  Resell
//
//  Created by Charles Liggins on 9/26/25.
//

import SwiftUI
import Combine

@MainActor
class FiltersViewModel: ObservableObject {
    @Published var categoryFilters: Set<String> = []
    @Published var conditionFilters: Set<String> = []
    @Published var lowValue: Double = 0
    @Published var highValue: Double = 1000
    @Published var showSale: Bool = false
    @Published var selectedSort: SortOption? = nil
    @Published var detailedFilterItems: [Post] = []
    @Published var searchedDetailedFilterItems: [Post] = [] // ✅ Added
    @Published var isSearching: Bool = false // ✅ Added
    
    private var baseCategory: String? = nil // Store the base category for detailed view

    func initializeDetailedFilter(category: String) async throws {
        baseCategory = category
        categoryFilters = [category] // Pre-populate with the category
        try await applyFilters(homeViewModel: HomeViewModel.shared)
    }
    
    // ✅ Added: Search within filtered items
    func searchWithinFilter(query: String) {
        guard !query.isEmpty else {
            searchedDetailedFilterItems = detailedFilterItems
            return
        }
        
        isSearching = true
        
        // Search within already filtered items
        searchedDetailedFilterItems = detailedFilterItems.filter { post in
            post.title.localizedCaseInsensitiveContains(query) ||
            post.description.localizedCaseInsensitiveContains(query) == true ||
            post.user?.username.localizedCaseInsensitiveContains(query) == true
        }
        
        isSearching = false
    }
    
    // ✅ Added: Clear search and show all filtered items
    func clearFilterSearch() {
        searchedDetailedFilterItems = detailedFilterItems
    }
        
    let isHome: Bool
    
    init(isHome: Bool = false) {
        self.isHome = isHome
    }
       
    // TODO: Use Unified endpoint
    func applyFilters(homeViewModel: HomeViewModel) async throws {
        let categoryFiltersList = Array(categoryFilters)
        let conditionFiltersList = Array(conditionFilters)

        var sortField: String

        if let selectedSort = selectedSort {
            switch selectedSort {
            case .any:
                sortField = "any"
            case .newlyListed:
                sortField = "newlyListed"
            case .priceHighToLow:
                sortField = "priceHighToLow"
            case .priceLowToHigh:
                sortField = "priceLowToHigh"
            }
        } else {
            sortField = "any"
        }
    
        let priceBody = PriceBody(lowerBound: Int(lowValue), upperBound: Int(highValue))
        let unifiedFilter = FilterPostsUnifiedRequest(
            sortField: sortField,
            price: priceBody,
            categories: categoryFiltersList,
            condition: conditionFiltersList
        )

        Task {
            do {
                let postsResponse = try await NetworkManager.shared.getUnifiedFilteredPosts(filters: unifiedFilter)
                if isHome {
                    homeViewModel.filteredItems = postsResponse.posts
                } else {
                    detailedFilterItems = postsResponse.posts
                    clearFilterSearch() // ✅ Update search results when filters change
                }
            } catch {
                NetworkManager.shared.logger.error("Error in FiltersViewModel.applyFilters: \(error)")
            }
        }
    }
    
    func resetFilters(homeViewModel: HomeViewModel) {
        categoryFilters.removeAll()
        conditionFilters.removeAll()
        lowValue = 0
        highValue = 1000
        showSale = false
        selectedSort = nil
        
        if isHome {
            homeViewModel.selectedFilter = ["Recent"]
        } else if let category = baseCategory {
            // For detailed view, reset to just the base category
            categoryFilters = [category]
            Task {
                try? await applyFilters(homeViewModel: homeViewModel)
            }
        }
    }
}
