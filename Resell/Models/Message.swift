//
//  Message.swift
//  Resell
//
//  Created by Peter Bidoshi on 2/25/25.
//  Created by Peter Bidoshi on 2/25/25.
//

import Foundation

protocol Message: Codable, Hashable {
    
    var messageId: String { get set }
    var messageType: MessageType { get }
    var timestamp: Date { get set }
    var read: Bool { get set }
    var mine: Bool { get set }
    var from: User { get set }
    /// Has this message been confirmed to have been sent?
    var sent: Bool { get set }

    func isEqual(to other: any Message) -> Bool
}

struct ChatMessage: Message {
    
    var messageId: String
    var messageType: MessageType = .chat
    var timestamp: Date
    var read: Bool = true
    var mine: Bool
    var from: User
    var sent: Bool = true
    var text: String
    var images: [String]

    func isEqual(to other: any Message) -> Bool {
        guard let otherMessage = other as? ChatMessage else {
            return false
        }

        return self.sent == otherMessage.sent && self.messageId == otherMessage.messageId
    }

}

struct AvailabilityMessage: Message {

    var messageId: String
    var messageType: MessageType = .availability
    var timestamp: Date
    var read: Bool = true
    var mine: Bool
    var from: User
    var sent: Bool = true
    var availabilities: [Availability]

    func isEqual(to other: any Message) -> Bool {
        guard let otherMessage = other as? AvailabilityMessage else {
            return false
        }

        return self.sent == otherMessage.sent && self.messageId == otherMessage.messageId
    }
}

struct ProposalMessage: Message {
    
    var messageId: String
    var messageType: MessageType = .proposal
    var timestamp: Date
    var read: Bool = true
    var mine: Bool
    var sent: Bool = true
    var from: User
    var startDate: Date
    var endDate: Date
    /// Has this proposal been accepted? `nil` if no action has been taken
    var accepted: Bool?
    /// Transaction ID (present when proposal is accepted)
    var transactionId: String?
    /// Has this proposal been cancelled?
    var cancellation: Bool?

    func isEqual(to other: any Message) -> Bool {
        guard let otherMessage = other as? ProposalMessage else {
            return false
        }

        return self.sent == otherMessage.sent && self.messageId == otherMessage.messageId
    }
}

struct Availability: Codable, Hashable {
    
    let startDate: Date
    let endDate: Date
}

enum MessageType: String, Codable {
    
    case chat = "message"
    case availability = "availability"
    case proposal = "proposal"
}

struct MessageBody: Codable {
    
    let type: MessageType
    let listingId: String
    let buyerId: String
    let sellerId: String
    let senderId: String
    let text: String?
    let images: [String]?
    let availabilities: [Availability]?
    let startDate: Date?
    let endDate: Date?
}

/// Body for responding to a proposal (accept/decline)
struct ProposalResponseBody: Codable {
    let senderId: String
    let listingId: String
    let buyerId: String
    let sellerId: String
    let startDate: Date
    let endDate: Date
    let accepted: Bool
}

/// Response from server when responding to a proposal
struct ProposalResponseResult: Codable {
    let type: String
    let senderID: String
    let timestamp: Date
    let accepted: Bool
    let startDate: Date
    let endDate: Date
    /// Transaction ID (only present when accepted = true)
    let transactionId: String?
}

struct ReadMessageRepsonse: Codable {
    
    let read: Bool
}
