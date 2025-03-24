//
//  MessageCluster.swift
//  Resell
//
//  Created by Peter Bidoshi on 2/26/25.
//

import SwiftUICore

struct MessageCluster: Identifiable, Equatable {
    let id: String
    let sender: MessageSender
    let location: MessageLocation
    let messages: [Message]

    static func == (lhs: MessageCluster, rhs: MessageCluster) -> Bool {
        if lhs.messages.count != rhs.messages.count { return false }

        for lhsMessage in lhs.messages {
            for rhsMessage in rhs.messages {
                if lhsMessage.messageId != rhsMessage.messageId {
                    return false
                }
            }
        }

        return true
    }
}

enum MessageSender {
    case user(user: User)
    // other message senders could be added here
}

enum MessageLocation {
    case left
    case right

    var alignment: HorizontalAlignment {
        switch self {
        case .left:
            return .leading
        case .right:
            return .trailing
        }
    }
}
