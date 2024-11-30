//
//  Chat.swift
//  Resell
//
//  Created by Richie Sun on 11/29/24.
//

import Foundation

struct Chat {
    var history: [ChatMessageCluster]
}

import FirebaseFirestore

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
}

struct ChatMessageCluster {
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
