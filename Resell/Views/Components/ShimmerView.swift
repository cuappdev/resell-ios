//
//  ShimmerView.swift
//  Resell
//
//  Created by Richie Sun on 11/4/24.
//

import SwiftUI

/// A reusable view that provides a shimmer (glimmer) effect, used as a placeholder for content that is loading.
struct ShimmerView: View {

    // MARK: - Properties

    @State private var shimmerOffset: CGFloat = -UIScreen.main.bounds.width

    // MARK: - UI

    var body: some View {
        GeometryReader { geometry in
            let gradientWidth = geometry.size.width * 0.6

            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))

                LinearGradient(
                    gradient: Gradient(colors: [.clear, .white.opacity(0.5), .clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: gradientWidth)
                .offset(x: shimmerOffset)
                .onAppear {
                    shimmerOffset = -gradientWidth
                    withAnimation(
                        Animation.linear(duration: 1)
                            .repeatForever(autoreverses: false)
                    ) {
                        shimmerOffset = geometry.size.width + gradientWidth
                    }
                }
            }
            .clipShape(Rectangle())
        }
    }
}

#Preview {
    ShimmerView()
        .frame(width: 300, height: 100)
}

