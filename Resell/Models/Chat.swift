//
//  Chat.swift
//  Resell
//
//  Created by Richie Sun on 11/29/24.
//

import Foundation

struct Chat: Identifiable {
    var id: Int { chatId }
    let seller: String
    let title: String
    let chatId: Int
    let chatType: ChatType
    let chatHistory: [ChatMessageCluster]
    var draftMessage: String
    var draftImages: [String]
}

enum ChatType: String {
    case purchases = "Purchases"
    case offers = "Offers"
}

struct ChatMessageCluster: Identifiable {
    let id = UUID()
    let senderId: Int
    let senderImage: String?
    let fromUser: Bool
    let messages: [ChatMessage]
}

struct ChatMessage: Identifiable {
    let id: Int
    let content: String
    let timestamp: TimeInterval
    let messageType: MessageType
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
