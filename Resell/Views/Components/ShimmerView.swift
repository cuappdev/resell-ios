//
//  ShimmerView.swift
//  Resell
//
//  Created by Richie Sun on 11/4/24.
//

import SwiftUI

/// A resuable view that provides a shimmer (glimmer) effect,  used as a placeholder for content that is loading
struct ShimmerView: View {

    // MARK: - Properties

    @State private var shimmerOffset: CGFloat = -UIScreen.main.bounds.width

    // MARK: - UI

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [.gray.opacity(0.3), .gray.opacity(0.1), .gray.opacity(0.3)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask(Rectangle())
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .white.opacity(0.3), .clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: shimmerOffset)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.0)
                        .repeatForever(autoreverses: false)
                ) {
                    shimmerOffset = UIScreen.main.bounds.width
                }
            }
    }
}
