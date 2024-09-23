//
//  View + Extensions.swift
//  Resell
//
//  Created by Richie Sun on 9/16/24.
//

import SwiftUI

extension View {

    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Dismisses the keyboard when the view is tapped.
    ///
    /// This view modifier can be applied to any SwiftUI view. When the user taps on the view,
    /// the keyboard will be dismissed if it is currently active.
    ///
    /// - Returns: A modified view with keyboard dismissal functionality.
    func endEditingOnTap() -> some View {
        self.modifier(EndEditingOnTap())
    }

}

struct EndEditingOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
    }
}

