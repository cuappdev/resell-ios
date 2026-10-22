//
//  Filter.swift
//  Resell
//
//  Created by Charles Liggins on 3/19/25.
//
import Foundation

struct FilterPostsUnifiedRequest: Codable {
    var sortField: String?
    var price: PriceBody?
    var categories: [String]?
    var condition: [String]?
}

extension FilterPostsUnifiedRequest {
    init(_ selection: FilterSelection) {
        self.init(
            sortField: selection.sort.sortField,
            price: PriceBody(lowerBound: Int(selection.lowPrice), upperBound: Int(selection.highPrice)),
            categories: selection.categories.sorted(),
            condition: selection.conditions.sorted()
        )
    }
}

/// Everything the filter sheet lets the user pick. Equal selections show the same posts.
struct FilterSelection: Equatable {
    var categories: Set<String> = []
    var conditions: Set<String> = []
    var lowPrice: Double = 0
    var highPrice: Double = 1000
    var sort: SortOption = .any
}

struct PriceBody: Codable {
    let lowerBound: Int
    let upperBound: Int
}

// we can prob refactor this...
struct ConditionBody: Codable {
    let conditions: [String]
}

