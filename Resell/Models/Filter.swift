//
//  Filter.swift
//  Resell
//
//  Created by Charles Liggins on 3/19/25.
//
import Foundation

struct PriceBody: Codable {
    let lowPrice: Int
    let maxPrice: Int
}

struct ConditionBody: Codable {
    let condition: String
}

struct CategoryBody: Codable {
    let category: String
}
