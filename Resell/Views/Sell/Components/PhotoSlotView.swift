//
//  PhotoSlotView.swift
//  Resell
//
//  Created by Ethan Chen on 11/4/26.
//

import SwiftUI

private enum PhotoSlotLayout {
    static let width: CGFloat = 231
    static let height: CGFloat = 294
    static let cornerRadius: CGFloat = 15
    static let borderWidth: CGFloat = 2
    static let dash: [CGFloat] = [6, 4]
    static let badgeInset: CGFloat = 16
    static let shadowY: CGFloat = 2
    static let coverPillHeight: CGFloat = 30
    static let addButtonSize = CGSize(width: 123, height: 30)
    static let addPhotoIconSize = CGSize(width: 47.25, height: 41.25)
    static let removeIconSize: CGFloat = 23
    static let removeButtonSize: CGFloat = 32
    static let removeButtonInset: CGFloat = 12
}

struct PhotoSlotView: View {

    enum Content: Equatable {
        case photo(UIImage)
        case add
        case empty
    }

    /// Half of Figma's blur of 10, since SwiftUI's radius spreads twice as far.
    static let shadowRadius: CGFloat = 5

    // MARK: - Properties

    let index: Int
    let content: Content
    var onAdd: () -> Void = {}
    var onRemove: () -> Void = {}

    // MARK: - UI

    var body: some View {
        card
            .frame(width: PhotoSlotLayout.width, height: PhotoSlotLayout.height)
            .overlay(alignment: .topLeading) {
                badge
                    .padding(PhotoSlotLayout.badgeInset)
            }
    }

    @ViewBuilder
    private var card: some View {
        switch content {
        case .photo(let image):
            photoCard(image)
        case .add:
            addCard
        case .empty:
            RoundedRectangle(cornerRadius: PhotoSlotLayout.cornerRadius)
                .fill(Constants.Colors.white)
                .overlay { dashedBorder(Constants.Colors.stroke) }
        }
    }

    private func photoCard(_ image: UIImage) -> some View {
        Color.clear
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipShape(RoundedRectangle(cornerRadius: PhotoSlotLayout.cornerRadius))
            .shadow(color: Constants.Colors.shadow, radius: Self.shadowRadius, y: PhotoSlotLayout.shadowY)
            .overlay(alignment: .topTrailing) {
                removeButton
                    .padding(PhotoSlotLayout.removeButtonInset)
            }
    }

    private var removeButton: some View {
        Button(action: onRemove) {
            Image("removePhoto")
                .resizable()
                .frame(width: PhotoSlotLayout.removeIconSize, height: PhotoSlotLayout.removeIconSize)
                .rotationEffect(.degrees(45))
                .frame(width: PhotoSlotLayout.removeButtonSize, height: PhotoSlotLayout.removeButtonSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove photo")
    }

    private var addCard: some View {
        Button(action: onAdd) {
            RoundedRectangle(cornerRadius: PhotoSlotLayout.cornerRadius)
                .fill(Constants.Colors.lightPurpleWash)
                .overlay {
                    VStack(spacing: 16) {
                        Image("addPhoto")
                            .resizable()
                            .frame(width: PhotoSlotLayout.addPhotoIconSize.width, height: PhotoSlotLayout.addPhotoIconSize.height)

                        HStack(spacing: 9) {
                            Image(systemName: "plus")
                            Text("Add")
                        }
                        .frame(width: PhotoSlotLayout.addButtonSize.width, height: PhotoSlotLayout.addButtonSize.height)
                        .purpleCapsule(font: Constants.Fonts.title3)
                    }
                }
                .overlay { dashedBorder(Constants.Colors.resellPurple) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add photo")
    }

    @ViewBuilder
    private var badge: some View {
        if index == 0 {
            Text("Cover")
                .font(Constants.Fonts.title3)
                .foregroundStyle(Constants.Colors.resellPurple)
                .padding(.horizontal, 10)
                .frame(height: PhotoSlotLayout.coverPillHeight)
                .outlinedCapsule(Constants.Colors.resellPurple, lineWidth: PhotoSlotLayout.borderWidth)
        } else {
            Text("\(index + 1)")
                .font(Constants.Fonts.title1)
                .foregroundStyle(Constants.Colors.inactiveGray)
        }
    }

    private func dashedBorder(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: PhotoSlotLayout.cornerRadius)
            .strokeBorder(color, style: StrokeStyle(lineWidth: PhotoSlotLayout.borderWidth, dash: PhotoSlotLayout.dash))
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack {
            PhotoSlotView(index: 0, content: .photo(UIImage(named: "justin") ?? UIImage()))
            PhotoSlotView(index: 1, content: .add)
            PhotoSlotView(index: 2, content: .empty)
        }
        .padding()
    }
}
