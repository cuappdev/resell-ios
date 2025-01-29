//
//  Chat.swift
//  Resell
//
//  Created by Richie Sun on 11/29/24.
//

import FirebaseFirestore
import Foundation

struct ChatPreview {
    let sellerName: String
    let email: String
    let recentItem: [String: Any]
    let image: URL?
    let recentMessage: String
    let recentSender: Int
    let viewed: Bool
    let confirmedTime: String
    let proposedTime: String?
    let proposedViewed: Bool
    let recentMessageTime: String
    let proposer: String?
    let items: [[String: Any]]
}

extension ChatPreview: Identifiable {
    var id: String { email }
}

struct Chat {
    var history: [ChatMessageCluster]
}

struct ChatMessageData: Identifiable {
    let id: String
    let timestamp: Timestamp
    let content: String
    let messageType: MessageType
    let imageUrl: String
    let post: Post?
    var timestampString: String {
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    var availability: AvailabilityDocument? = nil
}

struct ChatMessageCluster: Identifiable {
    var id: UUID = UUID()
    let senderId: String
    let senderImage: String?
    let fromUser: Bool
    let messages: [ChatMessageData]
}

enum MessageType: String {
    case image = "Image"
    case card = "Card"
    case message = "Message"
    case availability = "Availability"
    case state = "State"
}

enum MeetingProposalState: String {
    case userProposal = "UserProposal"
    case otherProposal = "OtherProposal"
    case userDecline = "UserDecline"
    case otherDecline = "OtherDecline"
}
