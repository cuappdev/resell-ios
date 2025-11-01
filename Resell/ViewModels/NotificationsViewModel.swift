//
//  NotificationsViewModel.swift
//  Resell
//
//  Created by Angelina Chen on 11/26/24.
//

import Firebase
import FirebaseFirestore
import SwiftUI

struct Notification: Identifiable {
    let id: String
    let title: String
    let body: String
    let type: String
    let referenceID: String
    var isRead: Bool = false
}

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
        Notification(id: "@audreywu", title: "New Message", body: "You have received a new message from Mateo", type: "messages", referenceID: "Alarm Clock"),
        Notification(id: "@angelinachen", title: "Request Received", body: "You have a new request from Angelina", type: "requests", referenceID: "Cowboy Boots"),
        Notification(id: "@angelinachen", title: "Bookmarked Item", body: "Your bookmarked item is back in stock", type: "bookmarks", referenceID: "Calculator"),
        Notification(id: "@laurenjun", title: "Order Update", body: "Your listing has been bookmarked", type: "your listings", referenceID: "Mini Fridge"),
    ]

    // MARK: - Computed Property for Filtered Notifications
    var filteredNotifications: [Notification] {
        if selectedTab == "All" {
            return notifications
        } else {
            return notifications.filter { $0.type.lowercased() == selectedTab.lowercased() }
        }
    }
    
    // Function to mark a notification as read
    func markAsRead(notification: Notification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
        }
    }

//    private let db = Firestore.firestore()

    // MARK: - Functions

    func fetchMessages() {
//        db.collection("chats")
//            .document(chatId)
//            .collection("messages")
//            .order(by: "createdAt", descending: false)
//            .addSnapshotListener { snapshot, error in
//                guard let documents = snapshot?.documents else {
//                    print("No documents or error: \(String(describing: error))")
//                    return
//                }
//
//                self.messages = documents.compactMap { document -> Message? in
//                    try? document.data(as: Message.self)
//                }
//            }
    }

}

