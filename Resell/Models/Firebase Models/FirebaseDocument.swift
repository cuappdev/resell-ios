//
//  FirebaseDocument.swift
//  Resell
//
//  Created by Richie Sun on 11/30/24.
//

import Foundation

struct FirebaseDocument: Codable {
    let venmo: String
    let onboarded: Bool
    let notificationsEnabled: Bool
    let fcmToken: String

    init(
        venmo: String = "",
        onboarded: Bool = false,
        notificationsEnabled: Bool = true,
        fcmToken: String = ""
    ) {
        self.venmo = venmo
        self.onboarded = onboarded
        self.notificationsEnabled = notificationsEnabled
        self.fcmToken = fcmToken
    }
}
