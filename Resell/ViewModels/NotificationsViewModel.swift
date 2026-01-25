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
    
    /// Unread notification counts by type
    @Published var unreadNotifs: [String: Int] = [
        "All": 0,
        "Messages": 0,
        "Requests": 0,
        "Bookmarks": 0,
        "Transactions": 0
    ]

    @Published var notifications: [Notifications] = [] {
        didSet {
            recalcLoadState()
            updateUnreadCounts()
        }
    }
    
    @Published var loadState: LoadState = .idle
    
    var filteredNotifications: [Notifications] {
        if selectedTab == "All" {
            return notifications
        } else {
            return notifications.filter { $0.data.resolvedType.lowercased() == selectedTab.lowercased() }
        }
    }
    
    private func recalcLoadState() {
        switch loadState {
        case .loading, .error:
            return
        default: break
        }
        loadState = filteredNotifications.isEmpty ? .empty : .success
    }
    
    private func updateUnreadCounts() {
        var counts: [String: Int] = [
            "All": 0,
            "Messages": 0,
            "Requests": 0,
            "Bookmarks": 0,
            "Transactions": 0
        ]
        
        for notification in notifications where !notification.read {
            counts["All", default: 0] += 1
            let type = notification.data.resolvedType.capitalized
            counts[type, default: 0] += 1
        }
        
        unreadNotifs = counts
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

    /// Mark a notification as read (calls backend)
    func markAsRead(notification: Notifications) {
        Task {
            do {
                let response = try await NetworkManager.shared.markNotificationAsRead(notificationId: notification.id)
                if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                    notifications[index] = response.notification
                }
            } catch {
                NetworkManager.shared.logger.error("Error marking notification as read: \(error.localizedDescription)")
                // Update locally as fallback
                if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                    notifications[index].read = true
                }
            }
        }
    }
    
    /// Remove a notification from local state
    func removeNotification(notification: Notifications) {
        withAnimation {
            notifications.removeAll(where: { $0.id == notification.id })
        }
    }
    
    /// Fetch notifications from backend (last 30 days)
    func fetchNotifications() {
        Task {
            loadState = .loading
            do {
                self.notifications = try await NetworkManager.shared.getLast30DaysNotifications()
                loadState = notifications.isEmpty ? .empty : .success
                print("✅ Fetched \(notifications.count) notifications")
            } catch {
                NetworkManager.shared.logger.error("Error in NotificationsViewModel.fetchNotifications: \(error.localizedDescription)")
                print("❌ Fetch notifications error: \(error)")
                
                // Fall back to empty state instead of error - notifications might just not exist yet
                self.notifications = []
                loadState = .empty
            }
        }
    }
    
    /// Fetch only new/unread notifications
    func fetchNewNotifications() {
        Task {
            loadState = .loading
            do {
                self.notifications = try await NetworkManager.shared.getNewNotifications()
                loadState = notifications.isEmpty ? .empty : .success
            } catch {
                NetworkManager.shared.logger.error("Error fetching new notifications: \(error.localizedDescription)")
                loadState = .error
            }
        }
    }
    
    // MARK: - Test Functions
    
    /// Create a test notification (for development only)
    /// - Parameter type: One of "messages", "requests", "bookmarks", "transactions"
    func createTestNotification(type: String) {
        Task {
            do {
                let response = try await NetworkManager.shared.createTestNotification(type: type)
                // Add to local list immediately
                notifications.insert(response.notification, at: 0)
                print("✅ Test notification created: \(response.notification.title)")
            } catch let urlError as URLError where urlError.code.rawValue == 404 {
                print("❌ Test endpoint not found (404). The /notif/test/\(type) endpoint may not be deployed yet.")
                print("   Tip: Use 'Load Dummy Data' to test the UI, or create real notifications through app actions.")
            } catch {
                NetworkManager.shared.logger.error("Error creating test notification: \(error.localizedDescription)")
                print("❌ Error creating test notification: \(error)")
            }
        }
    }
    
    /// Load dummy data for preview/testing
    func loadDummyData() {
        notifications = Notifications.dummydata
        loadState = .success
    }
}


