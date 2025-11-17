//
//  HapticFeedbackGenerator.swift
//  Resell
//
//  Created by Richie Sun on 11/8/24.
//

import UIKit

class HapticFeedbackGenerator {

    // MARK: - Impact Feedback

    /// Triggers an impact feedback of the specified style.
    /// - Parameter style: The style of the impact feedback (light, medium, heavy, rigid, soft).
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    // MARK: - Notification Feedback

    /// Triggers a notification feedback of the specified type.
    /// - Parameter type: The type of the notification feedback (success, warning, error).
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    // MARK: - Selection Feedback

    /// Triggers a selection feedback, typically used for changing selections.
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
