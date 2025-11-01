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
    @Published var presentPopup: Bool = false
    
    
    func applyFilters(homeViewModel: HomeViewModel) async throws {
        let categoryFiltersList = Array(categoryFilters)
        Task {
            print("Category Filters")
            print(categoryFiltersList)
             homeViewModel.selectedFilter = categoryFiltersList.isEmpty ? homeViewModel.selectedFilter : categoryFiltersList
        }
        let conditionFiltersList = Array(conditionFilters)
        Task {
            try await NetworkManager.shared.filterByCondition(conditions: conditionFiltersList)
        }
        
        if let sort = selectedSort {
            if selectedSort?.title == "Newly Listed" {
                Task { try await NetworkManager.shared.filterNewlyListed() }
            } else if selectedSort?.title == "Price: High to Low" {
                Task { try await NetworkManager.shared.filterPriceHightoLow() }
            } else if selectedSort?.title == "Price: Low to High" {
                Task { try await NetworkManager.shared.filterPriceLowtoHigh() }
            }
        }

        Task { try await NetworkManager.shared.filterByPrice(prices: PriceBody(lowPrice: Int(lowValue), maxPrice: Int(highValue))) }
        
        presentPopup = false
    }
    
    func resetFilters(homeViewModel: HomeViewModel) {
        categoryFilters.removeAll()
        conditionFilters.removeAll()
        lowValue = 0
        highValue = 1000
        showSale = false
        selectedSort = nil
        homeViewModel.selectedFilter = ["Recent"]
    }
}
