//
//  View + Extensions.swift
//  Resell
//
//  Created by Richie Sun on 9/16/24.
//

import SwiftUI
import UIKit

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

    /// Restores the system edge-swipe-to-pop while a custom back button hides
    /// the navigation bar item that normally owns that gesture.
    func enableSwipeBack() -> some View {
        background(InteractivePopGestureEnabler())
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

private struct InteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> InteractivePopGestureController {
        InteractivePopGestureController()
    }

    func updateUIViewController(_ uiViewController: InteractivePopGestureController, context: Context) {}
}

private final class InteractivePopGestureController: UIViewController, UIGestureRecognizerDelegate {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let popGesture = navigationController?.interactivePopGestureRecognizer else { return }
        popGesture.isEnabled = true
        popGesture.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if navigationController?.interactivePopGestureRecognizer?.delegate === self {
            navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        (navigationController?.viewControllers.count ?? 0) > 1
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        false
    }
}

