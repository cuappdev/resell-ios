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
    
    @Published var selectedTab: String = "All" {
        didSet { recalcLoadState() }
    }
    
    // MARK: - What is this for
    @Published var unreadNotifs: [String: Int] = [
        "All": 10,
        "Messages": 2,
        "Requests": 3,
        "Bookmarks": 1,
        "Your Listings": 5
    ]

    @Published var notifications: [Notifications] = Notifications.dummydata {
        didSet { recalcLoadState() }
    }
    // MARK: - turn back to .idle when we use actual backend networking
    @Published var loadState: LoadState = .success
    
    var filteredNotifications: [Notifications] {
        if selectedTab == "All" {
            return notifications
        } else {
            return notifications.filter { $0.data.type.lowercased() == selectedTab.lowercased() }        }
    }
    
    private func recalcLoadState() {
        switch loadState {
        case .loading, .error:
            return
        default: break
        }
        loadState = filteredNotifications.isEmpty ? .empty : .success
    }
    
    var groupedFilteredNotifications: [NotificationSection: [Notifications]] {
        let source = filteredNotifications
        let now = Date()
        let cal = Calendar.current
        
        var dict: [NotificationSection: [Notifications]] = [:]
        
        for noti in source {
            let days = cal.dateComponents([.day], from: noti.createdAt, to: now).day ?? 0
            let section: NotificationSection
            switch days {
            case 0: section = .new
            case 1...6: section = .last7
            case 7...29: section = .last30
            default: section = .older
            }
            dict[section, default: []].append(noti)
        }
        
        for section in dict.keys {
            dict[section]?.sort { $0.createdAt > $1.createdAt }
        }
        return dict
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
            loadState = .loading
            do {
                // MARK: - Check with backend to see if there are actually any notis
                self.notifications = try await NetworkManager.shared.getNotifications()
            } catch {
                NetworkManager.shared.logger.error("Error in NotificationsViewModel.fetchNotifications: \(error.localizedDescription)")
                loadState = .error
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


