//
//  Item.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import Foundation

struct Item: Codable, Hashable {

    static let defaultItem = Item(id: UUID(), title: "DJ Bustin", image: "justin", price: "25.00", category: "")

    let id: UUID
    let title: String
    let image: String
    let price: String
    let category: String
}
