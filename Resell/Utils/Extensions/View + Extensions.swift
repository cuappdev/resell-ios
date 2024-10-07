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

    /// Presents a popup modal at the center of the screen, over the view its applied to
    ///
    /// This view modifier can be applied to any SwiftUI view. When the user adds this modifier
    /// a popup modal view will be presented over the view when isPresented is true
    ///
    /// - Returns: A modified view with popup modal functionality.
    func popupModal<T: View>(isPresented: Binding<Bool>, @ViewBuilder content: () -> T) -> some View {
        self.modifier(PopupModal(isPresented: isPresented, content: content))
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

