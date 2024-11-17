//
//  Listing.swift
//  Resell
//
//  Created by Richie Sun on 11/16/24.
//

import Foundation

struct Listing: Codable {
    let id: String
    let title: String
    let images: [String]
    let originalPrice: Double
    let categories: [String]
    let description: String
    let user: User?

    enum CodingKeys: String, CodingKey {
        case id, title, description, categories
        case originalPrice = "original_price"
        case images, user
    }
}

struct ListingResponse: Codable {
    let post: Listing
}
