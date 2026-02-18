//
//  Notification.swift
//  Resell
//
//  Created by Angelina Chen on 12/1/24.
//

import Foundation

struct Notifications: Codable, Identifiable {
    let id: String
    let userId: String
    let title: String
    let body: String
    let data: NotificationData
    var read: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId, title, body, data, read, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        data = try container.decode(NotificationData.self, forKey: .data)
        read = try container.decode(Bool.self, forKey: .read)
        
        // Handle dates flexibly - try ISO8601, then Unix timestamp, then default to now
        createdAt = Self.decodeDate(from: container, forKey: .createdAt) ?? Date()
        updatedAt = Self.decodeDate(from: container, forKey: .updatedAt) ?? Date()
    }
    
    /// Attempts to decode a date from various formats
    private static func decodeDate(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Date? {
        // Try as ISO8601 string
        if let dateString = try? container.decode(String.self, forKey: key) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        
        // Try as Unix timestamp (Double)
        if let timestamp = try? container.decode(Double.self, forKey: key) {
            return Date(timeIntervalSince1970: timestamp)
        }
        
        // Try as Unix timestamp (Int)
        if let timestamp = try? container.decode(Int.self, forKey: key) {
            return Date(timeIntervalSince1970: Double(timestamp))
        }
        
        return nil
    }
    
    // For creating instances manually (previews, tests)
    init(id: String, userId: String, title: String, body: String, data: NotificationData, read: Bool, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.title = title
        self.body = body
        self.data = data
        self.read = read
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct NotificationData: Codable {
    // Type might be at different levels or named differently
    var type: String?
    var notificationType: String?
    
    // Optional fields that vary by notification type
    var imageUrl: String?
    var postId: String?
    var postTitle: String?
    var chatId: String?
    var sellerId: String?
    var sellerUsername: String?
    var sellerPhotoUrl: String?
    var buyerId: String?
    var buyerUsername: String?
    var transactionId: String?
    var price: Double?
    
    // Legacy field for compatibility
    var messageId: String?
    
    /// Returns the notification type from whichever field contains it
    var resolvedType: String {
        type ?? notificationType ?? "general"
    }
    
    /// Returns true if this is a transaction confirmation notification (buyer should confirm if meetup happened)
    var isTransactionConfirmation: Bool {
        let resolvedType = resolvedType.lowercased()
        return resolvedType == "transaction_confirmation" || resolvedType == "transactionconfirmation"
    }
    
    /// Flexible decoding - handles any JSON object structure
    init(from decoder: Decoder) throws {
        // Try to decode as a keyed container, but don't fail if keys are missing
        let container = try? decoder.container(keyedBy: DynamicCodingKeys.self)
        
        // Extract known fields if they exist
        type = container?.decodeIfPresentString(forKey: "type")
        notificationType = container?.decodeIfPresentString(forKey: "notificationType")
        imageUrl = container?.decodeIfPresentString(forKey: "imageUrl")
        postId = container?.decodeIfPresentString(forKey: "postId")
        postTitle = container?.decodeIfPresentString(forKey: "postTitle")
        chatId = container?.decodeIfPresentString(forKey: "chatId")
        sellerId = container?.decodeIfPresentString(forKey: "sellerId")
        sellerUsername = container?.decodeIfPresentString(forKey: "sellerUsername")
        sellerPhotoUrl = container?.decodeIfPresentString(forKey: "sellerPhotoUrl")
        buyerId = container?.decodeIfPresentString(forKey: "buyerId")
        buyerUsername = container?.decodeIfPresentString(forKey: "buyerUsername")
        transactionId = container?.decodeIfPresentString(forKey: "transactionId")
        messageId = container?.decodeIfPresentString(forKey: "messageId")
        
        // Try to decode price as Double or String
        // TODO: We should know the data type...
        if let priceDouble = try? container?.decodeIfPresent(Double.self, forKey: DynamicCodingKeys(stringValue: "price")!) {
            price = priceDouble
        } else if let priceString = container?.decodeIfPresentString(forKey: "price"),
                  let priceValue = Double(priceString) {
            price = priceValue
        } else {
            price = nil
        }
    }
}

// Helper for flexible key decoding
struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

extension KeyedDecodingContainer where K == DynamicCodingKeys {
    func decodeIfPresentString(forKey key: String) -> String? {
        guard let codingKey = DynamicCodingKeys(stringValue: key) else { return nil }
        return try? decodeIfPresent(String.self, forKey: codingKey)
    }
}

// MARK: - API Response Wrappers

struct NotificationsResponse: Codable {
    let notifications: [Notifications]
}

struct SingleNotificationResponse: Codable {
    let notification: Notifications
    let message: String?
}

struct MarkReadResponse: Codable {
    let message: String
    let notification: Notifications
}

enum NotificationSection: String, CaseIterable, Identifiable {
    case new = "New"
    case last7 = "Last 7 Days"
    case last30 = "Last 30 Days"
    case older = "Older"
    
    var id: String {rawValue}
}

enum LoadState {
    case idle
    case loading
    case success
    case empty
    case error
}
