//
//  MessageDocument.swift
//  Resell
//
//  Created by Peter Bidoshi on 2/25/25.
//

import FirebaseFirestore

/// Structure of each message document inside the messages subcollection of a chat on Firestore
struct MessageDocument: Codable, Hashable {

    @DocumentID var id: String?
    let type: MessageType
    let senderID: String
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

    static func == (lhs: MessageDocument, rhs: MessageDocument) -> Bool {
        lhs.id == rhs.id
    }

    /// Converts a MessageDocument to a Message
    func toMessage(buyer: User, seller: User) -> Message {
        let to = senderID == buyer.firebaseUid ? seller : buyer
        let from = senderID == buyer.firebaseUid ? buyer : seller

        let fromUser: Bool = from.firebaseUid == GoogleAuthManager.shared.user?.firebaseUid ?? ""

        switch type {
        case .chat:
            return ChatMessage(
                messageId: id,
                timestamp: timestamp,
                read: read,
                fromUser: fromUser,
                confirmed: true, text: text ?? "",
                images: images ?? []
            )
        case .availability:
            return AvailabilityMessage(
                messageId: id,
                timestamp: timestamp,
                read: read,
                fromUser: fromUser,
                confirmed: true,
                availabilities: availabilities ?? []
            )
        case .proposal:
            return ProposalMessage(
                messageId: id,
                timestamp: timestamp,
                read: read,
                fromUser: fromUser,
                confirmed: true,
                startDate: startDate ?? Date(),
                endDate: endDate ?? Date(),
                accepted: accepted
            )
        }
    }

}
