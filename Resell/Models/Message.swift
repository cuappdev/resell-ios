//
//  Message.swift
//  Resell
//
//  Created by Richie Sun on 10/26/24.
//

import SwiftUI

struct FirebaseUser: Codable, Identifiable {
    var id: String
    var avatar: String
    var name: String
}

struct Message: Codable, Identifiable {
    var id: String
    var text: String
    var createdAt: Date
    var user: FirebaseUser
    var isSentByCurrentUser: Bool
}

struct MessageBody: Codable {
    let id: String
}
