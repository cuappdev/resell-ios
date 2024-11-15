//
//  Post.swift
//  Resell
//
//  Created by Richie Sun on 11/3/24.
//

import Foundation

struct Post: Codable, Equatable, Identifiable {
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
    let user: User?

    enum CodingKeys: String, CodingKey {
        case id, title, description, categories
        case originalPrice = "original_price"
        case alteredPrice = "altered_price"
        case images, created, location, archive, user
    }
    
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }

    static func sortPostsByDate(_ posts: [Post], ascending: Bool = true) -> [Post] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        return posts.sorted {
            guard let date1 = dateFormatter.date(from: $0.created),
                  let date2 = dateFormatter.date(from: $1.created) else {
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
    let category: String
}

struct SearchRequest: Codable {
    let keywords: String
}

struct SavedResponse: Codable {
    let isSaved: Bool
}
