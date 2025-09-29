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

// we can prob refactor this...
struct ConditionBody: Codable {
    let conditions: [String]
}

