//
//  Post.swift
//  Resell
//
//  Created by Richie Sun on 11/3/24.
//

import Foundation

struct Post: Codable, Equatable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let category: String?
    let condition: String?
    let originalPrice: String
    let alteredPrice: String?
    let images: [String]
    let created: String
    let location: String?
    let archive: Bool
    let user: User?
    let sold: Bool?

    enum CodingKeys: String, CodingKey {
        case id, title, description, category, condition
        case originalPrice = "original_price"
        case alteredPrice = "altered_price"
        case images, created, location, archive, user, sold
    }

    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func sortPostsByDate(_ posts: [Post], ascending: Bool = false) -> [Post] {
        let isoDateFormatter = ISO8601DateFormatter()
        isoDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return posts.sorted {
            guard let date1 = isoDateFormatter.date(from: $0.created),
                  let date2 = isoDateFormatter.date(from: $1.created) else {
                return ascending
            }
            
            return ascending ? date1 < date2 : date1 > date2
        }
    }
}

struct PostsResponse: Codable {
    let posts: [Post]
}

struct PostResponse: Codable {
    let post: Post
}

struct FilterRequest: Codable {
    let categories: [String]
}

struct SearchRequest: Codable {
    let keywords: String
}

struct SavedResponse: Codable {
    let isSaved: Bool
}

struct PostBody: Codable {
    let title: String
    let description: String
    let category: String
    let originalPrice: Double
    let imagesBase64: [String]
    let userId: String
    let condition: String = "idk"

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case category
        case originalPrice = "original_price"
        case imagesBase64
        case userId
        case condition
    }
}
