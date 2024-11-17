//
//  LoadingView.swift
//  Resell
//
//  Created by Richie Sun on 11/12/24.
//

import SwiftUI

struct LoadingViewModifier: ViewModifier {

    let isLoading: Bool

    let size: CGFloat

    func body(content: Content) -> some View {
        ZStack {
            content

            if isLoading {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut, value: isLoading)

                CustomProgressView(size: size)
                    .transition(.opacity)
                    .animation(.easeInOut, value: isLoading)
            }
        }
    }


}

// MARK: - View Extension

extension View {

    /// - Displays an overlay with a progress view when `isLoading` is true.
    /// - `size` size of the spinner.
    func loadingView(isLoading: Bool, size: CGFloat = 100) -> some View {
        self.modifier(LoadingViewModifier(isLoading: isLoading, size: size))
    }
}
