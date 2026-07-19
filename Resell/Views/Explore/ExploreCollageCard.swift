//
//  ExploreCollageCard.swift
//  Resell
//

import SwiftUI

/// Square collage preview showing `min(posts.count, 10)` listing images.
struct ExploreCollageCard: View {

    let title: String
    let subtitle: String?
    let posts: [Post]
    let action: () -> Void

    private let maxImages = 10
    private let spacing: CGFloat = 2

    @State private var loadedStates: [Bool] = Array(repeating: false, count: 10)

    private var previewPosts: [Post] {
        Array(posts.prefix(maxImages))
    }

    var body: some View {
        Button(action: action) {
            GeometryReader { geo in
                ZStack(alignment: .bottomLeading) {
                    collage(size: geo.size)

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.75),
                            Color.black.opacity(0.35),
                            Color.clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: geo.size.height * 0.45)
                    .frame(maxHeight: .infinity, alignment: .bottom)

                    titleLabel
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .onChange(of: previewPosts.map(\.id)) { _ in
            loadedStates = Array(repeating: false, count: 10)
        }
    }

    private var titleLabel: some View {
        Group {
            if let subtitle, !subtitle.isEmpty {
                (
                    Text(title)
                        .font(Constants.Fonts.title1)
                        .foregroundStyle(.white)
                    + Text(" • \(subtitle)")
                        .font(Constants.Fonts.title4)
                        .foregroundStyle(.white.opacity(0.9))
                )
            } else {
                Text(title)
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(.white)
            }
        }
        .lineLimit(1)
    }

    @ViewBuilder
    private func collage(size: CGSize) -> some View {
        let urls = previewPosts.map { URL(string: $0.images.first ?? "") }
        let count = urls.count

        if count == 0 {
            Constants.Colors.wash
        } else if count == 1 {
            imageCell(url: urls[0], index: 0)
        } else if count == 2 {
            HStack(spacing: spacing) {
                imageCell(url: urls[0], index: 0)
                imageCell(url: urls[1], index: 1)
            }
        } else if count == 3 {
            HStack(spacing: spacing) {
                imageCell(url: urls[0], index: 0)
                VStack(spacing: spacing) {
                    imageCell(url: urls[1], index: 1)
                    imageCell(url: urls[2], index: 2)
                }
            }
        } else if count == 4 {
            VStack(spacing: spacing) {
                HStack(spacing: spacing) {
                    imageCell(url: urls[0], index: 0)
                    imageCell(url: urls[1], index: 1)
                }
                HStack(spacing: spacing) {
                    imageCell(url: urls[2], index: 2)
                    imageCell(url: urls[3], index: 3)
                }
            }
        } else {
            // 5–10: dense 3-column grid, clipped to the card
            let columns = [
                GridItem(.flexible(), spacing: spacing),
                GridItem(.flexible(), spacing: spacing),
                GridItem(.flexible(), spacing: spacing)
            ]
            let cellHeight = (size.height - spacing * 2) / 3

            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                    imageCell(url: url, index: index)
                        .frame(height: cellHeight)
                }
            }
            .frame(width: size.width, height: size.height, alignment: .top)
            .clipped()
        }
    }

    private func imageCell(url: URL?, index: Int) -> some View {
        CachedImageView(
            isImageLoaded: $loadedStates[index],
            imageURL: url
        )
        .clipped()
    }
}
