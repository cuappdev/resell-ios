//
//  MessageDocument.swift
//  Resell
//
//  Created by Peter Bidoshi on 2/25/25.
//

import FirebaseFirestore

/// A wrapper that can decode dates from multiple formats (Firestore Timestamp, numeric timestamp, or ISO string)
struct FlexibleDate: Codable, Hashable {
    let date: Date
    
    init(date: Date) {
        self.date = date
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try decoding as Firestore Timestamp (dictionary with _seconds and _nanoseconds)
        if let timestamp = try? container.decode(Timestamp.self) {
            self.date = timestamp.dateValue()
            return
        }
        
        // Try decoding as a numeric timestamp (milliseconds since epoch)
        if let milliseconds = try? container.decode(Double.self) {
            // Check if it's in seconds or milliseconds (Firestore uses seconds)
            if milliseconds > 1_000_000_000_000 {
                // Milliseconds
                self.date = Date(timeIntervalSince1970: milliseconds / 1000)
            } else {
                // Seconds
                self.date = Date(timeIntervalSince1970: milliseconds)
            }
            return
        }
        
        // Try decoding as an ISO8601 string
        if let dateString = try? container.decode(String.self) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                self.date = date
                return
            }
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                self.date = date
                return
            }
        }
        
        // Try decoding as a regular Date (Firestore default)
        if let date = try? container.decode(Date.self) {
            self.date = date
            return
        }
        
        throw DecodingError.typeMismatch(Date.self, DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "Could not decode date from any supported format"
        ))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(date)
    }
}

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
    let startDate: FlexibleDate?
    let endDate: FlexibleDate?
    let accepted: Bool?
    let transactionId: String?
    let cancellation: Bool?

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
                startDate: startDate?.date ?? Date(),
                endDate: endDate?.date ?? Date(),
                accepted: accepted,
                transactionId: transactionId,
                cancellation: cancellation
            )
        }
    }

}
