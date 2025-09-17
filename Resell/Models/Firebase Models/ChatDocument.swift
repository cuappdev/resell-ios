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

    /// Convert chat document to chat, using the current users user id
    func toChat(userId: String, messages: [MessageDocument]) async throws -> Chat {
        let post = try await NetworkManager.shared.getPostByID(id: listingID).post
        let buyer = try await NetworkManager.shared.getUserByID(id: buyerID).user
        let seller = try await NetworkManager.shared.getUserByID(id: sellerID).user

        guard let post else { throw ErrorResponse.userNotFound }

        return Chat(
            id: id,
            post: post,
            other: userId == buyerID ? seller : buyer,
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

