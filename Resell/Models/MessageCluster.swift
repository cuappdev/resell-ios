//
//  MessageCluster.swift
//  Resell
//
//  Created by Peter Bidoshi on 2/26/25.
//

import SwiftUICore

struct MessageCluster: Equatable {

    let id: String = UUID().uuidString
    let location: MessageLocation
    var messages: [any Message]

    static func == (lhs: MessageCluster, rhs: MessageCluster) -> Bool {
        if lhs.messages.count != rhs.messages.count { return false }

        for i in 0..<lhs.messages.count {
            if !lhs.messages[i].isEqual(to: rhs.messages[i]) { return false }
        }

        return true
    }

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
