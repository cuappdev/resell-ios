//
//  Transaction.swift
//  Resell
//
//  Created by Charles Liggins on 1/25/26.
//

import Foundation

struct Transaction: Codable, Identifiable, Hashable {
    let id: String
    let location: String?
    let amount: Double
    let transactionDate: Date
    let completed: Bool
    let post: PostSummary
    let buyer: UserSummary
    let seller: UserSummary
    
    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Summary Types
// These are lightweight versions of Post/User returned by the transaction endpoint
// They contain only the essential fields needed to display transaction info

struct PostSummary: Codable, Hashable {
    let id: String
    let title: String
    let images: [String]
    
    /// First image URL for display
    var firstImageURL: URL? {
        URL(string: images.first ?? "")
    }
}

struct UserSummary: Codable, Hashable {
    let id: String
    let firebaseUid: String
    let username: String
    let givenName: String
    let familyName: String
    let photoUrl: String?
    let email: String
    
    /// Full name for display
    var fullName: String {
        "\(givenName) \(familyName)"
    }
    
    /// Convenience to get photo URL
    var photoURL: URL? {
        guard let urlString = photoUrl else { return nil }
        return URL(string: urlString)
    }
}

// MARK: - Response Types

struct TransactionResponse: Codable {
    let transaction: Transaction
}

struct TransactionsResponse: Codable {
    let transactions: [Transaction]
}

// MARK: - Request Types

struct CompleteTransactionBody: Codable {
    let completed: Bool
}
