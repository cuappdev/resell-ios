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

    let index: Int
    var selectionIndex: Int = 0
    private let tabItems = ["home", "bookmark", "messages", "user"]

    // MARK: - UI
    
    var body: some View {
        Image(index == selectionIndex ? "\(tabItems[index])-selected" : tabItems[index])
            .resizable()
            .frame(width: 21, height: 21)
    }
    
}
