//
//  ResellLoginGradient.swift
//  Resell
//
//  Created by Richie Sun on 9/10/24.
//

import SwiftUI

/// Gradient background for login and launchscreen
struct LoginGradient: View {

    // MARK: - UI
    
    var body: some View {
        HStack(spacing: -30) {
            Ellipse()
                .fill(Constants.Colors.resellPurple)
                .frame(width: 650, height: 439)
                .opacity(0.3)
                .blur(radius: 115.56)
            Circle()
                .fill(Constants.Colors.resellBlurGradient1)
                .frame(width: 650, height: 650)
                .opacity(0.3)
                .blur(radius: 115.56)
        }
        .padding(.top, UIScreen.height * 0.75)
    }
}
