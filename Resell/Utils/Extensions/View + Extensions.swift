//
//  View + Extensions.swift
//  Resell
//
//  Created by Richie Sun on 9/16/24.
//

import SwiftUI

extension View {

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

