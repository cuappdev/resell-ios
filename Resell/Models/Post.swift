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
    let categories: [PostCategory]?
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
    var savedCount: Int? = nil
    var saveCount: Int? = nil
    var saves: Int? = nil
    /// Backend `getPostInfo()` exposes savers as a user array, not a numeric count.
    var savers: [PostSaver]? = nil

    var displaySaveCount: Int {
        [savedCount, saveCount, saves, savers?.count].compactMap { $0 }.max() ?? 0
    }

    /// Trending payloads often omit `savers`. If we already know this post is
    /// saved locally, treat that as at least one save.
    func ensuringMinimumSaves(_ minimum: Int) -> Post {
        guard minimum > displaySaveCount else { return self }
        var copy = self
        copy.savedCount = minimum
        return copy
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, categories, category, condition
        case originalPrice = "originalPrice"
        case alteredPrice = "alteredPrice"
        case images, created, location, archive, user, sold
        case savedCount, saveCount, saves, savers
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

/// Minimal saver payload so we can count `savers` without decoding full users.
struct PostSaver: Codable, Equatable, Hashable {
    let firebaseUid: String?
}

struct PostCategory: Codable {
    let id: String
    let name: String
}

struct PostsResponse: Codable {
    let posts: [Post]
}

struct PostResponse: Codable {
    let post: Post?
}

struct SearchedPostResponse: Codable {
    let posts: [Post]
    let searchId: String
}

struct FilterRequest: Codable {
    let categories: [String]
}

struct SuggestionsWrapper: Codable {
    let postIds: [String]
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
    let categories: [String]
    let condition: String
    let original_price: Double
    let imagesBase64: [String]
    let userId: String

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case categories
        case condition
        case original_price = "originalPrice"
        case imagesBase64
        case userId
    }
}
