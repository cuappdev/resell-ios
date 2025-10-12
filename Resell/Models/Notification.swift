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
    static let dummydata: [Notifications] = [
        Notifications(
            userID: "381527oef-42b4-4fdd-b074-dfwbejko229",
            title: "New Message",
            body: "You have received a new message from Mateo",
            data: NotificationData(type: "messages", messageId: "134841-42b4-4fdd-b074-jkfale"),
            createdAt: Date(),
            updatedAt: Date()
        ),
        Notifications(
            userID: "381527oef-42b4-4fdd-b074-dfwbejko229",
            title: "Request Received",
            body: "You have a new request from Angelina",
            data: NotificationData(type: "requests", messageId: "1"),
            createdAt: Date(),
            updatedAt: Date()
        ),
        Notifications(
            userID: "381527oef-42b4-4fdd-b074-dfwbejko229",
            title: "Bookmarked Item",
            body: "Your bookmarked item is back in stock",
            data: NotificationData(type: "bookmarks", messageId: "2"),
            createdAt: Date(),
            updatedAt: Date()
        ),
        Notifications(
            userID: "381527oef-42b4-4fdd-b074-dfwbejko229",
            title: "Order Update",
            body: "Your listing has been bookmarked",
            data: NotificationData(type: "your listings", messageId: "3"),
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}
