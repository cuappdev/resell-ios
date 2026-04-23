//
//  ChatDocument.swift
//  Resell
//
//  Created by Peter Bidoshi on 2/25/25.
//

import FirebaseFirestore

/// Structure of each chat document inside the chats collection on Firestore
struct ChatDocument: Codable {
    @DocumentID var id: String?
    let buyerID: String
    let lastMessage: String
    let listingID: String
    let sellerID: String
    let updatedAt: Date
    let userIDs: [String]

    /// Build a Chat from already-resolved post/buyer/seller. Pure: no network, no throws.
    /// Callers (e.g. `FirestoreManager`) are responsible for resolving these via
    /// `ChatProfileCache` so concurrent chats sharing a user/post share one fetch.
    func toChat(currentUserId: String, post: Post, buyer: User, seller: User, messages: [MessageDocument]) -> Chat {
        return Chat(
            id: id,
            post: post,
            other: currentUserId == buyerID ? seller : buyer,
            lastMessage: lastMessage,
            updatedAt: updatedAt,
            messages: messages.map { $0.toMessage(buyer: buyer, seller: seller) }
        )
    }

    static let buyerIdKey = CodingKeys.buyerID.stringValue
    static let sellerIdKey = CodingKeys.sellerID.stringValue
    static let idKey = CodingKeys.id.stringValue
    static let listingIdKey = CodingKeys.listingID.stringValue
}

