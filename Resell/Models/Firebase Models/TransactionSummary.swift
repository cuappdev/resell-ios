//
//  TransactionSummary.swift
//  Resell
//
//  Created by Richie Sun on 11/30/24.
//

import Foundation

struct TransactionSummary: Codable, Identifiable {
    var id: String { email ?? UUID().uuidString }
    let item: Post
    let recentMessage: String
    let recentMessageTime: String
    let recentSender: String
    let confirmedTime: String
    let confirmedViewed: Bool
    let name: String
    let image: String
    let viewed: Bool
    let email: String?
}