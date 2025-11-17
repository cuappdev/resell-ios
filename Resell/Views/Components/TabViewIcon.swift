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
        }
    }
    
}
