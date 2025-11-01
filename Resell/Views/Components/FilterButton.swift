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
    var unreadChats: Int = -1
    let isSelected: Bool
    let action: () -> Void

    // MARK: - UI

    var body: some View {
        Button(action: action, label: {
            HStack(spacing: 8) {
                Text(filter.title)
                    .font(Constants.Fonts.title3)
                    .foregroundStyle(Constants.Colors.black)
                if unreadChats > 0 {
                    Text("\(unreadChats)")
                        .font(.custom("Roboto-Medium", size: 12))
                        .foregroundStyle(Constants.Colors.white)
                        .frame(width: 18, height: 16)
                        .background(Constants.Colors.errorRed)
                        .clipShape(.capsule)
                }
            }
            .padding(12)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Constants.Colors.resellGradient, lineWidth: 2)
                } else {
                    if unreadChats < 0 {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Constants.Colors.stroke, lineWidth: 1)
                    }
                }
            }

        })
    }
}

