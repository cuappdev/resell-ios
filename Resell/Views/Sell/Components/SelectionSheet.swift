//
//  SelectionSheet.swift
//  Resell
//
//  Created by Ethan Chen on 11/11/26.
//

import Flow
import SwiftUI

private enum SelectionSheetLayout {
    static let cornerRadius: CGFloat = 20
    static let topPadding: CGFloat = 8
    static let bottomPadding: CGFloat = 36
    static let sectionSpacing: CGFloat = 40
    static let headerSpacing: CGFloat = 20
    static let grabberSize = CGSize(width: 65.5, height: 6)
    static let chipSpacing: CGFloat = 12
    static let chipPadding: CGFloat = 12
    static let chipBorderWidth: CGFloat = 1
    static let selectedChipBorderWidth: CGFloat = 2
    static let footerWidth: CGFloat = 296
    static let buttonHeight: CGFloat = 40
    static let buttonHorizontalPadding: CGFloat = 16
}

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
        VStack(spacing: SelectionSheetLayout.sectionSpacing) {
            header
            chips
            footer
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .padding(.top, SelectionSheetLayout.topPadding)
        .padding(.bottom, SelectionSheetLayout.bottomPadding)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Constants.Colors.white)
        .presentationDetents([.height(height)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(SelectionSheetLayout.cornerRadius)
    }

    private var header: some View {
        VStack(spacing: SelectionSheetLayout.headerSpacing) {
            Capsule()
                .fill(Constants.Colors.stroke)
                .frame(width: SelectionSheetLayout.grabberSize.width, height: SelectionSheetLayout.grabberSize.height)

            Text(title)
                .font(Constants.Fonts.h2)
                .foregroundStyle(Constants.Colors.black)
        }
    }

    private var chips: some View {
        HFlow(itemSpacing: SelectionSheetLayout.chipSpacing, rowSpacing: SelectionSheetLayout.chipSpacing) {
            ForEach(options, id: \.self) { option in
                chip(option)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(_ option: String) -> some View {
        let isSelected = draft == option

        return Button {
            draft = isSelected ? nil : option
        } label: {
            Text(option)
                .font(Constants.Fonts.title4)
                .foregroundStyle(Constants.Colors.black)
                .padding(SelectionSheetLayout.chipPadding)
                .outlinedCapsule(
                    isSelected ? AnyShapeStyle(Constants.Colors.resellGradient) : AnyShapeStyle(Constants.Colors.stroke),
                    lineWidth: isSelected ? SelectionSheetLayout.selectedChipBorderWidth : SelectionSheetLayout.chipBorderWidth
                )
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
                    .padding(.horizontal, SelectionSheetLayout.buttonHorizontalPadding)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                onApply(draft)
            } label: {
                Text("Apply")
                    .padding(.horizontal, SelectionSheetLayout.buttonHorizontalPadding)
                    .frame(height: SelectionSheetLayout.buttonHeight)
                    .purpleCapsule()
            }
            .buttonStyle(.plain)
            .disabled(!hasChanges)
        }
        .frame(width: SelectionSheetLayout.footerWidth)
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            SelectionSheet(
                title: "Category",
                options: ["Clothing", "Books", "School", "Electronics", "Household", "Sports & Outdoors", "Other"],
                selection: "Other",
                height: 310
            )
        }
}
