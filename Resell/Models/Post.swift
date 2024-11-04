//
//  Post.swift
//  Resell
//
//  Created by Richie Sun on 11/3/24.
//

import Foundation

struct PostResponse: Codable {
    let posts: [Post]
}

struct Post: Codable {
    let id: String
    let title: String
    let description: String
    let categories: [String]
    let originalPrice: String
    let alteredPrice: String
    let images: [URL]
    let created: String
    let location: String?
    let archive: Bool
    let user: User

    enum CodingKeys: String, CodingKey {
        case id, title, description, categories
        case originalPrice = "original_price"
        case alteredPrice = "altered_price"
        case images, created, location, archive, user
    }
}

struct MatchedItem: Codable {
    let id: String
    let title: String
    let description: String
    let user: User
    let matches: [Post]
}
