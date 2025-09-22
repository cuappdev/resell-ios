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
    var read: Bool?

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

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Converts a MessageDocument to a Message
    func toMessage(buyer: User, seller: User) -> any Message {
        let from = senderID == buyer.firebaseUid ? buyer : seller
        let fromUser: Bool = from.firebaseUid == GoogleAuthManager.shared.user?.firebaseUid ?? ""
        let id = id ?? UUID().uuidString

        switch type {
        case .chat:
            return ChatMessage(
                messageId: id,
                timestamp: timestamp,
                read: read ?? true,
                mine: fromUser,
                from: from,
                text: text ?? "",
                images: images ?? []
            )
        case .availability:
            return AvailabilityMessage(
                messageId: id,
                timestamp: timestamp,
                mine: fromUser,
                from: from,
                availabilities: availabilities?.map{ $0 } ?? []
            )
        case .proposal:
            return ProposalMessage(
                messageId: id,
                timestamp: timestamp,
                mine: fromUser,
                from: from,
                startDate: startDate ?? Date(),
                endDate: endDate ?? Date(),
                accepted: accepted
            )
        }
    }

}
