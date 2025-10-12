//
//  Notification.swift
//  Resell
//
//  Created by Angelina Chen on 12/1/24.
//

import Foundation
// Original name Notification overrides Foundation definition...
struct Notifications: Codable {
    let userID: String
    let title: String
    let body: String
    let data: NotificationData
    var isRead: Bool = false
    let createdAt: Date
    let updatedAt: Date
}

struct NotificationData: Codable {
    let type: String
    let messageId: String
}

enum NotificationSection: String, CaseIterable, Identifiable {
    case new = "New"
    case last7 = "Last 7 Days"
    case last30 = "Last 30 Days"
    case older = "Older"
    
    var id: String {rawValue}
}

extension Notifications {
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
            // === New (same day, within 24h) ===
            Notifications(
                userID: "user-mateo",
                title: "New Message",
                body: "You have received a new message from Mateo",
                data: NotificationData(type: "message", messageId: "msg-0001"),
                createdAt: hoursAgo(1),
                updatedAt: hoursAgo(1)
            ),
            Notifications(
                userID: "user-angelina",
                title: "Request Received",
                body: "You have a new request from Angelina",
                data: NotificationData(type: "requests", messageId: "req-0001"),
                createdAt: hoursAgo(5),
                updatedAt: hoursAgo(5)
            ),
            Notifications(
                userID: "user-lina",
                title: "Bookmarked Item",
                body: "Your bookmarked item is back in stock",
                data: NotificationData(type: "bookmarks", messageId: "bm-0001"),
                createdAt: hoursAgo(12),
                updatedAt: hoursAgo(12)
            ),
            Notifications(
                userID: "user-jay",
                title: "Listing Activity",
                body: "Your listing has been bookmarked",
                data: NotificationData(type: "your listings", messageId: "yl-0001"),
                createdAt: hoursAgo(20),
                updatedAt: hoursAgo(20)
            ),

            // === Last 7 Days (1–6 days) ===
            Notifications(
                userID: "user-sam",
                title: "New Message",
                body: "Sam: Is this still available?",
                data: NotificationData(type: "message", messageId: "msg-0002"),
                createdAt: daysAgo(1),
                updatedAt: daysAgo(1)
            ),
            Notifications(
                userID: "user-zoe",
                title: "Request Updated",
                body: "Zoe updated her request",
                data: NotificationData(type: "requests", messageId: "req-0002"),
                createdAt: daysAgo(2),
                updatedAt: daysAgo(2)
            ),
            Notifications(
                userID: "user-rio",
                title: "Discount Alert",
                body: "An item you bookmarked was discounted",
                data: NotificationData(type: "bookmarks", messageId: "bm-0002"),
                createdAt: daysAgo(3),
                updatedAt: daysAgo(3)
            ),
            Notifications(
                userID: "user-noah",
                title: "Listing Saved",
                body: "Noah bookmarked your listing",
                data: NotificationData(type: "your listings", messageId: "yl-0002"),
                createdAt: daysAgo(4),
                updatedAt: daysAgo(4)
            ),
            Notifications(
                userID: "user-ivy",
                title: "New Message",
                body: "Ivy sent you a follow-up",
                data: NotificationData(type: "message", messageId: "msg-0003"),
                createdAt: daysAgo(6),
                updatedAt: daysAgo(6)
            ),

            // === Last 30 Days (7–29 days) ===
            Notifications(
                userID: "user-ken",
                title: "Request Accepted",
                body: "Ken accepted your offer",
                data: NotificationData(type: "requests", messageId: "req-0003"),
                createdAt: daysAgo(7),
                updatedAt: daysAgo(7)
            ),
            Notifications(
                userID: "user-luca",
                title: "Price Drop",
                body: "Bookmarked item dropped in price",
                data: NotificationData(type: "bookmarks", messageId: "bm-0003"),
                createdAt: daysAgo(10),
                updatedAt: daysAgo(10)
            ),
            Notifications(
                userID: "user-mia",
                title: "Listing Saved",
                body: "Mia bookmarked your listing",
                data: NotificationData(type: "your listings", messageId: "yl-0003"),
                createdAt: daysAgo(15),
                updatedAt: daysAgo(15)
            ),
            Notifications(
                userID: "user-omar",
                title: "New Message",
                body: "Omar sent a question about size",
                data: NotificationData(type: "message", messageId: "msg-0004"),
                createdAt: daysAgo(20),
                updatedAt: daysAgo(20)
            ),
            Notifications(
                userID: "user-pia",
                title: "Request Withdrawn",
                body: "Pia withdrew a request",
                data: NotificationData(type: "requests", messageId: "req-0004"),
                createdAt: daysAgo(28),
                updatedAt: daysAgo(28)
            ),

            // === Older (30+ days) ===
            Notifications(
                userID: "user-quinn",
                title: "Old Message",
                body: "Quinn asked about shipping",
                data: NotificationData(type: "message", messageId: "msg-0005"),
                createdAt: daysAgo(31),
                updatedAt: daysAgo(31)
            ),
            Notifications(
                userID: "user-ryan",
                title: "Past Request",
                body: "Ryan's request expired",
                data: NotificationData(type: "requests", messageId: "req-0005"),
                createdAt: daysAgo(45),
                updatedAt: daysAgo(45)
            ),
            Notifications(
                userID: "user-sara",
                title: "Old Bookmark",
                body: "Sara bookmarked a while ago",
                data: NotificationData(type: "bookmarks", messageId: "bm-0004"),
                createdAt: daysAgo(60),
                updatedAt: daysAgo(60)
            ),
            Notifications(
                userID: "user-tim",
                title: "Older Listing Activity",
                body: "Tim bookmarked your listing previously",
                data: NotificationData(type: "your listings", messageId: "yl-0004"),
                createdAt: daysAgo(120),
                updatedAt: daysAgo(120)
            )
        ]
    }()
}

