//
//  HomeViewModel.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {

    @Published var selectedFilters: Set<FilterCategory> = []

    // Toggle the filter in the selectedFilters set
    func toggleFilter(_ filter: FilterCategory) {
        if selectedFilters.contains(filter) {
            selectedFilters.remove(filter)
        } else {
            selectedFilters.insert(filter)
        }
    }

}
