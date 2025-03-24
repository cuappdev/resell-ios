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
    let listingId: String
    let buyerId: String
    let sellerId: String
    let lastMessage: String
    let updatedAt: Date
    let messageDocuments: [MessageDocument]

    /// Convert chat document to chat, using the current users user id
    func toChat(userId: String) async throws -> Chat {
        let post = try await NetworkManager.shared.getPostByID(id: listingId).post
        let buyer = try await NetworkManager.shared.getUserByID(id: buyerId).user
        let seller = try await NetworkManager.shared.getUserByID(id: sellerId).user

        return Chat(
            id: id,
            post: post,
            other: userId == buyerId ? seller : buyer,
            lastMessage: lastMessage,
            updatedAt: updatedAt,
            messages: messageDocuments.map { $0.toMessage(buyer: buyer, seller: seller) }
        )
    }

    static let buyerIdKey = CodingKeys.buyerId.stringValue
    static let sellerIdKey = CodingKeys.sellerId.stringValue
    static let idKey = CodingKeys.id.stringValue
}

