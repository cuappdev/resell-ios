//
//  PhotoSlotView.swift
//  Resell
//
//  Created by Ethan Chen on 11/4/26.
//

import SwiftUI

struct PhotoSlotView: View {

    enum Content: Equatable {
        case photo(UIImage)
        case add
        case empty
    }

    // MARK: - Properties

    let index: Int
    let content: Content
    var onAdd: () -> Void = {}
    var onRemove: () -> Void = {}

    private var isCover: Bool {
        index == 0
    }

    // MARK: - UI

    var body: some View {
        card
            .frame(width: Constants.Sell.photoSlotWidth, height: Constants.Sell.photoSlotHeight)
            .overlay(alignment: .topLeading) {
                badge
                    .padding(Constants.Sell.photoSlotBadgeInset)
            }
    }

    @ViewBuilder
    private var card: some View {
        switch content {
        case .photo(let image):
            photoSlot(image)
        case .add:
            addSlot
        case .empty:
            emptySlot
        }
    }

    // MARK: - Photo

    private func photoSlot(_ image: UIImage) -> some View {
        Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(slotShape)
            .shadow(
                color: Constants.Colors.shadow,
                radius: Constants.Sell.photoShadowRadius,
                y: Constants.Sell.photoShadowY
            )
            .overlay(alignment: .topTrailing) {
                removeButton
                    .padding(Constants.Sell.removeButtonInset)
            }
    }

    private var removeButton: some View {
        Button(action: onRemove) {
            Image("removePhoto")
                .resizable()
                .frame(width: Constants.Sell.removeIconSize, height: Constants.Sell.removeIconSize)
                .rotationEffect(.degrees(45))
                .frame(width: Constants.Sell.removeButtonSize, height: Constants.Sell.removeButtonSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add

    private var addSlot: some View {
        Button(action: onAdd) {
            slotShape
                .fill(Constants.Colors.lightPurpleWash)
                .overlay {
                    VStack(spacing: 16) {
                        Image("addPhoto")
                            .resizable()
                            .frame(width: Constants.Sell.addPhotoIconSize.width, height: Constants.Sell.addPhotoIconSize.height)

                        addLabel
                    }
                }
                .overlay {
                    dashedBorder(Constants.Colors.resellPurple)
                }
        }
        .buttonStyle(.plain)
    }

    private var addLabel: some View {
        HStack(spacing: 9) {
            Image(systemName: "plus")
            Text("Add")
        }
        .font(Constants.Fonts.title3)
        .foregroundStyle(Constants.Colors.white)
        .frame(width: Constants.Sell.addButtonWidth, height: Constants.Sell.addButtonHeight)
        .background(Constants.Colors.resellPurple)
        .clipShape(Capsule())
    }

    // MARK: - Empty

    private var emptySlot: some View {
        slotShape
            .fill(Constants.Colors.white)
            .overlay {
                dashedBorder(Constants.Colors.stroke)
            }
    }

    // MARK: - Shared

    @ViewBuilder
    private var badge: some View {
        if isCover {
            coverPill
        } else {
            slotNumber
        }
    }

    private var coverPill: some View {
        Text("Cover")
            .font(Constants.Fonts.title3)
            .foregroundStyle(Constants.Colors.resellPurple)
            .padding(.horizontal, 10)
            .frame(height: Constants.Sell.coverPillHeight)
            .background(Constants.Colors.white)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Constants.Colors.resellPurple, lineWidth: Constants.Sell.photoSlotBorderWidth)
            }
    }

    private var slotNumber: some View {
        Text("\(index + 1)")
            .font(Constants.Fonts.title1)
            .foregroundStyle(Constants.Colors.inactiveGray)
    }

    private var slotShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Constants.Sell.photoSlotCornerRadius)
    }

    private func dashedBorder(_ color: Color) -> some View {
        slotShape
            .strokeBorder(
                color,
                style: StrokeStyle(lineWidth: Constants.Sell.photoSlotBorderWidth, dash: Constants.Sell.photoSlotDash)
            )
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack(spacing: Constants.Sell.photoSlotSpacing) {
            PhotoSlotView(index: 0, content: .photo(UIImage(named: "justin") ?? UIImage()))
            PhotoSlotView(index: 1, content: .add)
            PhotoSlotView(index: 2, content: .empty)
        }
        .padding()
    }
}
