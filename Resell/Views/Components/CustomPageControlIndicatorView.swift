//
//  CustomPageControl.swift
//  Resell
//
//  Created by Richie Sun on 10/14/24.
//

import SwiftUI

/// Custom Page Control
struct CustomPageControlIndicatorView: View {

    // MARK: - Properties

    @Binding var currentPage: Int
    var numberOfPages: Int

    // MARK: - UI

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Constants.Colors.secondaryGray : Constants.Colors.inactiveGray)
                    .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 12 : 8)
                    .animation(.easeInOut, value: currentPage)
            }
        }
        .padding(.vertical, 10)
    }

}
