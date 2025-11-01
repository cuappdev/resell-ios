//
//  ChatDocument.swift
//  Resell
//
//  Created by Richie Sun on 11/30/24.
//

import Foundation
import FirebaseFirestore

struct ChatDocument: Codable, Identifiable {
    let id: String
    let createdAt: Timestamp
    let image: String
    let text: String
    let user: UserDocument
    let availability: AvailabilityDocument?
    let product: Post?
}

struct AvailabilityDocument: Codable {
    let test: String
}


