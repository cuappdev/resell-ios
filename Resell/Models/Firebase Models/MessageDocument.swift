//
//  MessageDocument.swift
//  Resell
//
//  Created by Peter Bidoshi on 2/25/25.
//

import FirebaseFirestore

/// Structure of each message document inside the messages subcollection of a chat on Firestore
struct MessageDocument: Codable {
    @DocumentID var id: String?
    let type: MessageType
    let senderId: String
    let timestamp: Date
    let read: Bool

    // Normal Message Fields
    let text: String?
    let images: [String]?

    // Availability Message Fields
    let availabilities: [Availability]?

    // Proposal Message Fields
    let startDate: Date?
    let endDate: Date?
    let accepted: Bool?

    /// Converts a MessageDocument to a Message
    func toMessage(buyer: User, seller: User) -> Message {
        let to = senderId == buyer.firebaseUid ? seller : buyer
        let from = senderId == buyer.firebaseUid ? buyer : seller

        switch type {
        case .chat:
            return ChatMessage(
                messageId: id,
                to: to,
                from: from,
                timestamp: timestamp,
                read: read,
                text: text ?? "",
                images: images ?? []
            )
        case .availability:
            return AvailabilityMessage(
                messageId: id,
                to: to,
                from: from,
                timestamp: timestamp,
                read: read,
                availabilities: availabilities ?? []
            )
        case .proposal:
            return ProposalMessage(
                messageId: id,
                to: to,
                from: from,
                timestamp: timestamp,
                read: read,
                startDate: startDate ?? Date(),
                endDate: endDate ?? Date(),
                accepted: accepted
            )
        }
    }

}
