//
//  FCMNotification.swift
//  Resell
//
//  Created by Richie Sun on 12/3/24.
//

import Foundation

struct FcmBody: Codable {
    let message: FcmMessage
}

struct FcmMessage: Codable {
    let token: String
    let notification: FcmNotification?
    let data: NotificationData
}

struct FcmNotification: Codable {
    let title: String
    let body: String
}

struct NotificationData: Codable {
    let navigationId: String
}
