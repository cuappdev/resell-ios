//
//  ResellFilterButton.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import SwiftUI

/// Custom button for item filters
struct FilterButton: View {
    
    // MARK: - Properties

    let filter: FilterCategory
    let isSelected: Bool
    let action: () -> Void

    // MARK: - UI

    var body: some View {
        Button(action: action, label: {
            Text(filter.title)
                .font(Constants.Fonts.title3)
                .foregroundStyle(Constants.Colors.black)
                .padding(12)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Constants.Colors.resellGradient, lineWidth: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Constants.Colors.stroke, lineWidth: 1)
                    }
                }

        })
    }
}
