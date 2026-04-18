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
    let confirmationSent: Bool?
    let post: PostSummary?      // Optional - not always included (e.g., in transaction reviews)
    let buyer: UserSummary?     // Optional - not always included
    let seller: UserSummary?    // Optional - not always included
    
    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Custom decoding to handle amount as String and dates with fractional seconds
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        completed = try container.decode(Bool.self, forKey: .completed)
        confirmationSent = try container.decodeIfPresent(Bool.self, forKey: .confirmationSent)
        post = try container.decodeIfPresent(PostSummary.self, forKey: .post)
        buyer = try container.decodeIfPresent(UserSummary.self, forKey: .buyer)
        seller = try container.decodeIfPresent(UserSummary.self, forKey: .seller)
        
        // Handle amount as either String or Double
        if let amountDouble = try? container.decode(Double.self, forKey: .amount) {
            amount = amountDouble
        } else if let amountString = try? container.decode(String.self, forKey: .amount),
                  let amountDouble = Double(amountString) {
            amount = amountDouble
        } else {
            amount = 0
        }
        
        // Handle transactionDate - backend sends ISO8601 strings like "2026-01-28T03:12:55.810Z"
        // Note: transactionDate can be null in database
        let rawDate: Date
        if let dateString = try? container.decode(String.self, forKey: .transactionDate) {
            print("📅 Transaction \(id) date decoded as String: '\(dateString)'")
            if let parsed = Transaction.parseDate(dateString) {
                rawDate = parsed
                print("📅 Parsed to Date: \(rawDate)")
            } else {
                print("📅 Failed to parse string '\(dateString)', using current date")
                rawDate = Date()
            }
        }
        // Fallback: try decoder's date strategy (iso8601)
        else if let date = try? container.decode(Date.self, forKey: .transactionDate) {
            print("📅 Transaction \(id) date decoded via decoder strategy: \(date)")
            rawDate = date
        }
        // Handle null or missing value
        else {
            print("📅 Transaction \(id) transactionDate is null or missing, using current date")
            rawDate = Date()
        }
        
        // Sanity check: if the date is before 2020, the backend likely sent a null/zero value
        // that serialized to an epoch-era date. Use current date instead.
        let cutoffDate = Calendar.current.date(from: DateComponents(year: 2020, month: 1, day: 1))!
        if rawDate < cutoffDate {
            print("⚠️ Transaction \(id) date \(rawDate) is before 2020 — backend likely sent null/zero. Using current date.")
            transactionDate = Date()
        } else {
            transactionDate = rawDate
        }
    }
    
    /// Parse ISO8601 date string with or without fractional seconds
    static func parseDate(_ dateString: String) -> Date? {
        // Try with fractional seconds first (e.g., "2026-01-28T03:12:55.810Z")
        let formatterWithFractional = ISO8601DateFormatter()
        formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatterWithFractional.date(from: dateString) {
            return date
        }
        
        // Try without fractional seconds (e.g., "2026-01-28T03:12:55Z")
        let formatterWithoutFractional = ISO8601DateFormatter()
        formatterWithoutFractional.formatOptions = [.withInternetDateTime]
        if let date = formatterWithoutFractional.date(from: dateString) {
            return date
        }
        
        return nil
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, location, amount, transactionDate, completed, confirmationSent, post, buyer, seller
    }
}

// MARK: - Summary Types
// These are lightweight versions of Post/User returned by the transaction endpoint
// They contain only the essential fields needed to display transaction info

struct PostSummary: Codable, Hashable {
    let id: String
    let title: String
    let images: [String]
    let description: String?
    let condition: String?
    let originalPrice: String?
    let alteredPrice: String?
    let sold: Bool?
    
    /// First image URL for display
    var firstImageURL: URL? {
        URL(string: images.first ?? "")
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, title, images, description, condition, sold
        case originalPrice = "originalPrice"
        case alteredPrice = "alteredPrice"
    }
}

struct UserSummary: Codable, Hashable {
    let firebaseUid: String
    let username: String
    let givenName: String
    let familyName: String
    let photoUrl: String?
    let email: String
    let netid: String?
    let bio: String?
    let venmoHandle: String?
    
    /// Use firebaseUid as the identifier
    var id: String { firebaseUid }
    
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

// MARK: - Review Types

struct TransactionReview: Codable, Identifiable {
    let id: String
    let stars: Int
    let comments: String?
    let hadIssues: Bool
    let issueCategory: String?
    let issueDetails: String?
    let createdAt: Date?
    let transaction: Transaction?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        stars = try container.decode(Int.self, forKey: .stars)
        comments = try container.decodeIfPresent(String.self, forKey: .comments)
        hadIssues = try container.decode(Bool.self, forKey: .hadIssues)
        issueCategory = try container.decodeIfPresent(String.self, forKey: .issueCategory)
        issueDetails = try container.decodeIfPresent(String.self, forKey: .issueDetails)
        transaction = try container.decodeIfPresent(Transaction.self, forKey: .transaction)
        
        // Flexible date decoding for createdAt
        if let dateString = try? container.decode(String.self, forKey: .createdAt) {
            createdAt = Transaction.parseDate(dateString)
        } else {
            createdAt = nil
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, stars, comments, hadIssues, issueCategory, issueDetails, createdAt, transaction
    }
}

struct TransactionReviewResponse: Codable {
    let review: TransactionReview
    
    init(review: TransactionReview) {
        self.review = review
    }
}

struct CreateTransactionReviewBody: Codable {
    let transactionId: String
    let stars: Int
    let comments: String?
    let hadIssues: Bool
    let issueCategory: String?
    let issueDetails: String?
}

struct UserReview: Codable, Identifiable {
    let id: String
    let fulfilled: Bool
    let stars: Int
    let comments: String?
    let buyer: UserSummary?
    let seller: UserSummary?
    let date: String?  // Backend returns "date" field
}

struct UserReviewResponse: Codable {
    let review: UserReview
    
    init(review: UserReview) {
        self.review = review
    }
}

struct UserReviewsResponse: Codable {
    let reviews: [UserReview]
}

struct TransactionReviewsResponse: Codable {
    let reviews: [TransactionReview]
}

struct CreateUserReviewBody: Codable {
    let buyerId: String   // The reviewer (current user)
    let sellerId: String  // The user being reviewed
    let fulfilled: Bool
    let stars: Int
    let comments: String
}
