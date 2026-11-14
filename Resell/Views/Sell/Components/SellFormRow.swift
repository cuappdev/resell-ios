//
//  SellFormRow.swift
//  Resell
//
//  Created by Ethan Chen on 11/11/26.
//

import SwiftUI

private enum SellFormRowLayout {
    static let valueSpacing: CGFloat = 12
    static let optionalTagSpacing: CGFloat = 8
    static let optionalDotSize: CGFloat = 5
}

struct SellFormRow: View {

    // MARK: - Properties

    let label: String
    let value: String?
    let placeholder: String
    var isOptional = false
    var action: () -> Void = {}

    // MARK: - UI

    var body: some View {
        Button(action: action) {
            HStack {
                labelView

                Spacer()

                valueView
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var labelView: some View {
        HStack(spacing: SellFormRowLayout.optionalTagSpacing) {
            Text(label)
                .font(Constants.Fonts.h3)
                .foregroundStyle(Constants.Colors.black)

            if isOptional {
                Circle()
                    .fill(Constants.Colors.mutedGray)
                    .frame(width: SellFormRowLayout.optionalDotSize, height: SellFormRowLayout.optionalDotSize)

                Text("optional")
                    .font(Constants.Fonts.body1)
                    .foregroundStyle(Constants.Colors.mutedGray)
            }
        }
    }

    private var valueView: some View {
        HStack(spacing: SellFormRowLayout.valueSpacing) {
            Text(value ?? placeholder)
                .font(Constants.Fonts.title1)
                .foregroundStyle(value == nil ? Constants.Colors.mutedGray : Constants.Colors.black)

            Image("dropdownArrow")
                .rotationEffect(.degrees(-90))
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SellFormRow(label: "Category", value: nil, placeholder: "Choose")
        SellFormRow(label: "Condition", value: "Never Used", placeholder: "Choose")
        SellFormRow(label: "Event", value: nil, placeholder: "None", isOptional: true)
    }
    .padding()
}
