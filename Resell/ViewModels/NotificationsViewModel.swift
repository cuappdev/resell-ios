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
        // Update locally immediately for responsive UI
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].read = true
        }
        
        // Then sync with backend
        Task {
            do {
                let updated = try await NetworkManager.shared.markNotificationAsRead(notificationId: notification.id)
                if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                    notifications[index] = updated
                }
            } catch {
                NetworkManager.shared.logger.error("Error marking notification as read: \(error.localizedDescription)")
                // Local update already applied, so user still sees it as read
            }
        }
    }
    
    /// Delete a notification from backend and remove from local state
    func removeNotification(notification: Notifications) {
        // Remove locally immediately for responsive UI
        withAnimation {
            notifications.removeAll(where: { $0.id == notification.id })
        }
        
        // Then delete from backend
        Task {
            do {
                try await NetworkManager.shared.deleteNotification(notificationId: notification.id)
            } catch {
                NetworkManager.shared.logger.error("Error deleting notification: \(error.localizedDescription)")
                // Notification already removed locally - if backend fails, it will reappear on next fetch
                // which is acceptable behavior
            }
        }
    }
    
    /// Fetch notifications from backend (last 30 days)
    func fetchNotifications() {
        Task {
            loadState = .loading
            do {
                let allNotifications = try await NetworkManager.shared.getLast30DaysNotifications()
                self.notifications = deduplicateNotifications(allNotifications)
                loadState = notifications.isEmpty ? .empty : .success
            } catch {
                NetworkManager.shared.logger.error("Error in NotificationsViewModel.fetchNotifications: \(error.localizedDescription)")
                
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
                let allNotifications = try await NetworkManager.shared.getNewNotifications()
                self.notifications = deduplicateNotifications(allNotifications)
                loadState = notifications.isEmpty ? .empty : .success
            } catch {
                NetworkManager.shared.logger.error("Error fetching new notifications: \(error.localizedDescription)")
                loadState = .error
            }
        }
    }
    
    // MARK: - Deduplication
    
    /// Removes duplicate notifications based on content similarity within a time window
    /// This is a frontend safeguard - backend should also prevent duplicate sends
    private func deduplicateNotifications(_ notifications: [Notifications]) -> [Notifications] {
        var seen = Set<String>()
        var result: [Notifications] = []
        
        // Sort by createdAt descending so we keep the most recent one
        let sorted = notifications.sorted { $0.createdAt > $1.createdAt }
        
        for notification in sorted {
            let key = deduplicationKey(for: notification)
            if !seen.contains(key) {
                seen.insert(key)
                result.append(notification)
            }
        }
        
        return result
    }
    
    /// Creates a deduplication key based on notification content
    /// Notifications with the same key within a short time window are considered duplicates
    private func deduplicationKey(for notification: Notifications) -> String {
        let type = notification.data.resolvedType.lowercased()
        let postId = notification.data.postId ?? ""
        let senderId = notification.data.buyerId ?? notification.data.sellerId ?? ""
        
        // Round timestamp to nearest minute to catch near-simultaneous duplicates
        let timeWindow = Int(notification.createdAt.timeIntervalSince1970 / 60)
        
        return "\(type)_\(postId)_\(senderId)_\(timeWindow)"
    }
    
    // MARK: - Transaction Confirmation
    
    /// Confirm or deny that a transaction happened
    /// - Parameters:
    ///   - notification: The transaction confirmation notification
    ///   - completed: Whether the transaction actually happened
    func confirmTransaction(notification: Notifications, completed: Bool) {
        guard let transactionId = notification.data.transactionId else {
            NetworkManager.shared.logger.error("No transactionId in notification for confirmation")
            return
        }
        
        // Mark notification as read
        markAsRead(notification: notification)
        
        Task {
            do {
                if completed {
                    // Mark transaction as completed in backend
                    _ = try await NetworkManager.shared.completeTransaction(transactionId: transactionId)
                }
                // Remove the confirmation notification after handling
                removeNotification(notification: notification)
            } catch {
                NetworkManager.shared.logger.error("Error confirming transaction: \(error.localizedDescription)")
            }
        }
    }
    
}


