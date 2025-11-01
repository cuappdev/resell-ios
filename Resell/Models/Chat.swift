//
//  ChatPreview.swift
//  Resell
//
//  Created by Peter Bidoshi on 2/25/25.
//

import Foundation

struct Chat: Identifiable {
    let id: String?
    let post: Post
    let other: User
    let lastMessage: String
    let updatedAt: Date
    let messages: [Message]
}

struct SimpleChatInfo: Equatable, Hashable {
    let listingId: String
    let buyerId: String
    let sellerId: String

    func toChatInfo() async throws -> ChatInfo {
        let post = try await NetworkManager.shared.getPostByID(id: listingId).post
        let buyer = try await NetworkManager.shared.getUserByID(id: buyerId).user
        let seller = try await NetworkManager.shared.getUserByID(id: sellerId).user

        return ChatInfo(listing: post, buyer: buyer, seller: seller)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(listingId + buyerId + sellerId)
    }

    static func == (lhs: SimpleChatInfo, rhs: SimpleChatInfo) -> Bool {
        return lhs.listingId == rhs.listingId && lhs.buyerId == rhs.buyerId && lhs.sellerId == rhs.sellerId
    }
}

struct ChatInfo {
    let listing: Post
    let buyer: User
    let seller: User
}
