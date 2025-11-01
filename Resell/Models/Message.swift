//
//  Message.swift
//  Resell
//
//  Created by Peter Bidoshi on 2/25/25.
//

import Foundation

protocol Message {
    var messageId: String? { get set }
    var messageType: MessageType { get }
    var timestamp: Date { get set }
    var read: Bool { get set }
    var fromUser: Bool { get set }
    /// Has this message been confirmed to have been sent?
    var confirmed: Bool { get set }
}

struct ChatMessage: Message {
    var messageId: String?
    var messageType: MessageType = .chat
    var timestamp: Date
    var read: Bool
    var fromUser: Bool
    var confirmed: Bool
    var text: String
    var images: [String]
}

struct AvailabilityMessage: Message {
    var messageId: String?
    var messageType: MessageType = .availability
    var timestamp: Date
    var read: Bool
    var fromUser: Bool
    var confirmed: Bool
    var availabilities: [Availability]
}

struct ProposalMessage: Message {
    var messageId: String?
    var messageType: MessageType = .proposal
    var timestamp: Date
    var read: Bool
    var fromUser: Bool
    var confirmed: Bool
    var startDate: Date
    var endDate: Date
    /// Has this proposal been accepted? `nil` if no action has been taken
    var accepted: Bool?
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

struct UpdateMessageBody: Codable {
    let read: Bool
}
