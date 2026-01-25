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

struct TestNotificationResponse: Codable {
    let message: String
    let notification: Notifications
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

extension Notifications {
    /// Creates dummy notification data for testing/preview purposes
    static func makeDummyData(
        id: String = UUID().uuidString,
        type: String,
        title: String,
        body: String,
        createdAt: Date
    ) -> Notifications {
        Notifications(
            id: id,
            userId: "dummy-user",
            title: title,
            body: body,
            data: NotificationData(
                type: type,
                imageUrl: nil,
                postId: nil,
                postTitle: nil,
                chatId: nil,
                sellerId: nil,
                sellerUsername: nil,
                sellerPhotoUrl: nil,
                buyerId: nil,
                buyerUsername: nil,
                transactionId: nil,
                price: nil,
                messageId: id
            ),
            read: false,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
    
    static let dummydata: [Notifications] = {
        let now = Date()
        let cal = Calendar.current

        func hoursAgo(_ h: Int) -> Date {
            now.addingTimeInterval(TimeInterval(-h * 3600))
        }
        func daysAgo(_ d: Int) -> Date {
            cal.date(byAdding: .day, value: -d, to: now)!
        }

        return [
            makeDummyData(id: "msg-0001", type: "messages", title: "New Message", body: "You have received a new message from Mateo", createdAt: hoursAgo(1)),
            makeDummyData(id: "req-0001", type: "requests", title: "Request Received", body: "You have a new request from Angelina", createdAt: hoursAgo(5)),
            makeDummyData(id: "bm-0001", type: "bookmarks", title: "Bookmarked Item", body: "Your bookmarked item is back in stock", createdAt: hoursAgo(12)),
            makeDummyData(id: "msg-0002", type: "messages", title: "New Message", body: "Sam: Is this still available?", createdAt: daysAgo(1)),
            makeDummyData(id: "req-0002", type: "requests", title: "Request Updated", body: "Zoe updated her request", createdAt: daysAgo(2)),
            makeDummyData(id: "bm-0002", type: "bookmarks", title: "Discount Alert", body: "An item you bookmarked was discounted", createdAt: daysAgo(3)),
            makeDummyData(id: "msg-0003", type: "messages", title: "New Message", body: "Ivy sent you a follow-up", createdAt: daysAgo(6)),
            makeDummyData(id: "req-0003", type: "requests", title: "Request Accepted", body: "Ken accepted your offer", createdAt: daysAgo(7)),
            makeDummyData(id: "bm-0003", type: "bookmarks", title: "Price Drop", body: "Bookmarked item dropped in price", createdAt: daysAgo(10)),
            makeDummyData(id: "msg-0004", type: "messages", title: "New Message", body: "Omar sent a question about size", createdAt: daysAgo(20)),
            makeDummyData(id: "req-0004", type: "requests", title: "Request Withdrawn", body: "Pia withdrew a request", createdAt: daysAgo(28)),
            makeDummyData(id: "msg-0005", type: "messages", title: "Old Message", body: "Quinn asked about shipping", createdAt: daysAgo(31)),
            makeDummyData(id: "req-0005", type: "requests", title: "Past Request", body: "Ryan's request expired", createdAt: daysAgo(45)),
            makeDummyData(id: "bm-0004", type: "bookmarks", title: "Old Bookmark", body: "Sara bookmarked a while ago", createdAt: daysAgo(60)),
        ]
    }()
}

