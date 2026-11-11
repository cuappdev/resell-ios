//
//  SelectionSheet.swift
//  Resell
//
//  Created by Ethan Chen on 11/11/26.
//

import Flow
import SwiftUI

struct SelectionSheet: View {

    // MARK: - Properties

    let title: String
    let options: [String]
    let selection: String?
    let height: CGFloat
    let onApply: (String?) -> Void

    @State private var draft: String?

    private var hasChanges: Bool {
        draft != selection
    }

    init(
        title: String,
        options: [String],
        selection: String?,
        height: CGFloat = 0,
        onApply: @escaping (String?) -> Void = { _ in }
    ) {
        self.title = title
        self.options = options
        self.selection = selection
        self.height = height
        self.onApply = onApply
        _draft = State(initialValue: selection)
    }

    // MARK: - UI

    var body: some View {
        VStack(spacing: Constants.Sell.sheetSectionSpacing) {
            header
            chips
            footer
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .padding(.top, Constants.Sell.sheetTopPadding)
        .padding(.bottom, Constants.Sell.sheetBottomPadding)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Constants.Colors.white)
        .presentationDetents([.height(height)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(Constants.Sell.sheetCornerRadius)
    }

    private var header: some View {
        VStack(spacing: Constants.Sell.sheetHeaderSpacing) {
            Capsule()
                .fill(Constants.Colors.stroke)
                .frame(width: Constants.Sell.grabberSize.width, height: Constants.Sell.grabberSize.height)

            Text(title)
                .font(Constants.Fonts.h2)
                .foregroundStyle(Constants.Colors.black)
        }
    }

    private var chips: some View {
        HFlow(itemSpacing: Constants.Sell.chipSpacing, rowSpacing: Constants.Sell.chipSpacing) {
            ForEach(options, id: \.self) { option in
                chip(option)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(_ option: String) -> some View {
        Button {
            draft = draft == option ? nil : option
        } label: {
            Text(option)
                .font(Constants.Fonts.title4)
                .foregroundStyle(Constants.Colors.black)
                .padding(Constants.Sell.chipPadding)
                .background(Constants.Colors.white)
                .clipShape(Capsule())
                .overlay {
                    if draft == option {
                        Capsule()
                            .strokeBorder(Constants.Colors.resellGradient, lineWidth: Constants.Sell.selectedChipBorderWidth)
                    } else {
                        Capsule()
                            .strokeBorder(Constants.Colors.stroke, lineWidth: Constants.Sell.chipBorderWidth)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack {
            Button {
                draft = nil
            } label: {
                Text("Reset")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.mediumGray)
                    .padding(.horizontal, Constants.Sell.sheetButtonHorizontalPadding)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                onApply(draft)
            } label: {
                Text("Apply")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.white)
                    .padding(.horizontal, Constants.Sell.sheetButtonHorizontalPadding)
                    .frame(height: Constants.Sell.sheetButtonHeight)
                    .background(Constants.Colors.resellPurple)
                    .clipShape(Capsule())
                    .opacity(hasChanges ? 1 : Constants.Sell.disabledOpacity)
            }
            .buttonStyle(.plain)
            .disabled(!hasChanges)
        }
        .frame(width: Constants.Sell.sheetFooterWidth)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            SelectionSheet(title: "Category", options: Constants.Sell.categories, selection: "Other", height: 310)
        }
}
