//
//  HomeViewModel.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {

    static let shared = HomeViewModel()

    @Published var allItems: [Item] = Constants.dummyItemsData

    @Published var savedItems: [Item] = [
        Item(id: UUID(), title: "Justin", image: "justin", price: "$100", category: "School"),
        Item(id: UUID(), title: "Justin", image: "justin_long", price: "$100", category: "School"),
        Item(id: UUID(), title: "Justin", image: "justin_long", price: "$100", category: "School")
    ]

    @Published var selectedFilter: String = "Recent"


}
