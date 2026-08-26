//
//  TabViewIcon.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import SwiftUI

/// Icons for main tab view
struct TabViewIcon: View {

    // MARK: - Properties

    @Binding var selectionIndex: Int

    let itemIndex: Int
    var badgeCount: Int = 0

    private let tabItems = ["home", "messages", "user"]

    // MARK: - UI

    var body: some View {
        Button {
            selectionIndex = itemIndex
        } label: {
            Image(itemIndex == selectionIndex ? "\(tabItems[itemIndex])-selected" : tabItems[itemIndex])
                .resizable()
                .frame(width: 28, height: 28)
                .tint(Constants.Colors.inactiveGray)
                .overlay(alignment: .topTrailing) {
                    if badgeCount > 0 {
                        Text(badgeCount > 99 ? "99+" : "\(badgeCount)")
                            .font(.custom("Roboto-Medium", size: 10))
                            .foregroundStyle(Constants.Colors.white)
                            .padding(.horizontal, 5)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Constants.Colors.errorRed)
                            .clipShape(.capsule)
                            .offset(x: 10, y: -8)
                    }
                }
        }
    }
}
