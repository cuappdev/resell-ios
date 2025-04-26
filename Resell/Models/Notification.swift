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
}

struct NotificationData: Codable {
    let type: String
    let messageId: String
}
