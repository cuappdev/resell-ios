//
//  NotificationsViewModel.swift
//  Resell
//
//  Created by Angelina Chen on 11/26/24.
//

import Firebase
import FirebaseFirestore
import SwiftUI

@MainActor
class NotificationsViewModel: ObservableObject {

    // MARK: - Properties
    
    @Published var selectedTab: String = "All"
    @Published var unreadNotifs: [String: Int] = [
        "All": 10,
        "Messages": 2,
        "Requests": 3,
        "Bookmarks": 1,
        "Your Listings": 5
    ]

    @Published var notifications: [Notification] = [
        Notification(
            userID: "381527oef-42b4-4fdd-b074-dfwbejko229",
            title: "New Message",
            body: "You have received a new message from Mateo",
            data: NotificationData(type: "messages", messageId: "134841-42b4-4fdd-b074-jkfale")
        ),
        Notification(
            userID: "381527oef-42b4-4fdd-b074-dfwbejko229",
            title: "Request Received",
            body: "You have a new request from Angelina",
            data: NotificationData(type: "requests", messageId: "1")
        ),
        Notification(
            userID: "381527oef-42b4-4fdd-b074-dfwbejko229",
            title: "Bookmarked Item",
            body: "Your bookmarked item is back in stock",
            data: NotificationData(type: "bookmarks", messageId: "2")
        ),
        Notification(
            userID: "381527oef-42b4-4fdd-b074-dfwbejko229",
            title: "Order Update",
            body: "Your listing has been bookmarked",
            data: NotificationData(type: "your listings", messageId: "3")
        )
    ]

    var filteredNotifications: [Notification] {
        if selectedTab == "All" {
            return notifications
        } else {
            return notifications.filter { $0.data.type.lowercased() == selectedTab.lowercased() }
        }
    }

    // MARK: - Functions

    /// Mark a notification as read
    func markAsRead(notification: Notification) {
        if let index = notifications.firstIndex(where: { $0.data.messageId == notification.data.messageId}) {
            notifications[index].isRead = true
        }
    }

    /// Simulate fetching data
    func fetchNotifications() {
        notifications = [
            Notification(
                userID: "381527oef-42b4-4fdd-b074-dfwbejko229",
                title: "New Message",
                body: "You have received a new message from Mateo",
                data: NotificationData(type: "messages", messageId: "12345")
            ),
            Notification(
                userID: "381527oef-42b4-4fdd-b074-dfwbejko229",
                title: "New Request",
                body: "You have a new request from Angelina",
                data: NotificationData(type: "requests", messageId: "23456")
            )
        ]
    }
}


