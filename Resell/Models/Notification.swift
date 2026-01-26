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
        if let priceDouble = try? container?.decodeIfPresent(Double.self, forKey: DynamicCodingKeys(stringValue: "price")!) {
            price = priceDouble
        } else if let priceString = container?.decodeIfPresentString(forKey: "price"),
                  let priceValue = Double(priceString) {
            price = priceValue
        } else {
            price = nil
        }
    }
    
    // For creating dummy data
    init(type: String?, notificationType: String? = nil, imageUrl: String? = nil, postId: String? = nil, 
         postTitle: String? = nil, chatId: String? = nil, sellerId: String? = nil, 
         sellerUsername: String? = nil, sellerPhotoUrl: String? = nil, buyerId: String? = nil,
         buyerUsername: String? = nil, transactionId: String? = nil, price: Double? = nil, messageId: String? = nil) {
        self.type = type
        self.notificationType = notificationType
        self.imageUrl = imageUrl
        self.postId = postId
        self.postTitle = postTitle
        self.chatId = chatId
        self.sellerId = sellerId
        self.sellerUsername = sellerUsername
        self.sellerPhotoUrl = sellerPhotoUrl
        self.buyerId = buyerId
        self.buyerUsername = buyerUsername
        self.transactionId = transactionId
        self.price = price
        self.messageId = messageId
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


