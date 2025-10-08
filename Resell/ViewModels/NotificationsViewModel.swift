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

    @Published var notifications: [Notifications] = Notifications.dummydata

    var filteredNotifications: [Notifications] {
        if selectedTab == "All" {
            return notifications
        } else {
            return notifications.filter { $0.data.type.lowercased() == selectedTab.lowercased() }
        }
    }

    // MARK: - Functions

    /// Mark a notification as read
    func markAsRead(notification: Notifications) {
        if let index = notifications.firstIndex(where: { $0.data.messageId == notification.data.messageId}) {
            notifications[index].isRead = true
        }
    }
    
    func fetchNotifications() {
        Task {
            do {
                // MARK: - Check with backend to see if there are actually any notis
                print(self.notifications)
                self.notifications = try await NetworkManager.shared.getNotifications()
                print(self.notifications)
            } catch {
                NetworkManager.shared.logger.error("Error in NotificationsViewModel.fetchNotifications: \(error)")
            }
        }
    }

    /// Simulate fetching data
    func dummyFetchNotifications() {
        notifications = [
            Notifications(
                userID: "381527oef-42b4-4fdd-b074-dfwbejko229",
                title: "New Message",
                body: "You have received a new message from Mateo",
                data: NotificationData(type: "messages", messageId: "12345"),
                createdAt: Date(),
                updatedAt: Date()
            ),
            Notifications(
                userID: "381527oef-42b4-4fdd-b074-dfwbejko229",
                title: "New Request",
                body: "You have a new request from Angelina",
                data: NotificationData(type: "requests", messageId: "23456"),
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
}


