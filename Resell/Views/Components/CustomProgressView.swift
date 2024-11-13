//
//  ResellProgressView.swift
//  Resell
//
//  Created by Richie Sun on 11/12/24.
//

import SwiftUI

struct CustomProgressView: View {

    @State private var isAnimating = false

    var color: Color = Constants.Colors.resellPurple

    var size: CGFloat = 100

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(color, lineWidth: 8)
            .frame(width: size, height: size)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                .linear(duration: 1).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    CustomProgressView()
}

