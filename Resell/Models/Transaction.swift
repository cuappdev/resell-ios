//
//  Transaction.swift
//  Resell
//
//  Created by Charles Liggins on 1/25/26.
//

import Foundation

struct Transaction: Codable, Identifiable {
    let id: String
    let location: String?
    let amount: Double
    let transactionDate: Date
    let completed: Bool
    let post: TransactionPost
    let buyer: TransactionUser
    let seller: TransactionUser
}

struct TransactionPost: Codable {
    let id: String
    let title: String
    let images: [String]?
}

struct TransactionUser: Codable {
    let id: String
    let firebaseUid: String
    let username: String
    let givenName: String
    let familyName: String
    let photoUrl: String?
    let email: String
}

struct TransactionResponse: Codable {
    let transaction: Transaction
}

struct TransactionsResponse: Codable {
    let transactions: [Transaction]
}

struct CompleteTransactionBody: Codable {
    let completed: Bool
}
