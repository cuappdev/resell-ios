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
    let messages: [any Message]
}

struct ChatInfo: Equatable, Hashable {
    let listing: Post
    let buyer: User
    let seller: User

    static func == (lhs: ChatInfo, rhs: ChatInfo) -> Bool {
        return lhs.listing.id == rhs.listing.id
        && lhs.buyer.firebaseUid == rhs.buyer.firebaseUid
        && lhs.seller.firebaseUid == rhs.seller.firebaseUid
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(listing.id)
        hasher.combine(buyer.firebaseUid)
        hasher.combine(seller.firebaseUid)
    }
}
