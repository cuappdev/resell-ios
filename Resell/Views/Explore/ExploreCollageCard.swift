//
//  ExploreCollageCard.swift
//  Resell
//

import SwiftUI

/// Collage preview showing either one image or a four-image grid.
struct ExploreCollageCard: View {

    let title: String
    let subtitle: String?
    let posts: [Post]
    let action: () -> Void

    private let spacing: CGFloat = 2

    @State private var loadedStates: [Bool] = Array(repeating: false, count: 4)

    private var previewPosts: [Post] {
        Array(posts.prefix(posts.count >= 4 ? 4 : 1))
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geo in
                    collage(size: geo.size)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
                // Slightly wider than tall so cards sit a bit shorter than a square.
                .aspectRatio(1.12, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                titleLabel
            }
        }
        .buttonStyle(.plain)
        .onChange(of: previewPosts.map(\.id)) { _ in
            loadedStates = Array(repeating: false, count: 4)
        }
    }

    private var titleLabel: some View {
        Group {
            if let subtitle, !subtitle.isEmpty {
                if #available(iOS 17.0, *) {
                    (
                        Text(title)
                            .font(Constants.Fonts.title2)
                            .foregroundStyle(Constants.Colors.black)
                        + Text(" • \(subtitle)")
                            .font(Constants.Fonts.title2)
                            .foregroundStyle(Constants.Colors.black)
                    )
                } else {
                    // Fallback on earlier versions
                }
            } else {
                Text(title)
                    .font(Constants.Fonts.title2)
                    .foregroundStyle(Constants.Colors.black)
            }
        }
        .lineLimit(1)
    }

    @ViewBuilder
    private func collage(size: CGSize) -> some View {
        let urls = previewPosts.map { URL(string: $0.images.first ?? "") }
        let count = urls.count
        let cellWidth = (size.width - spacing) / 2
        let cellHeight = (size.height - spacing) / 2

        if count == 0 {
            Constants.Colors.wash
        } else if count == 1 {
            imageCell(url: urls[0], index: 0)
                .frame(width: size.width, height: size.height)
                .clipped()
        } else {
            VStack(spacing: spacing) {
                HStack(spacing: spacing) {
                    imageCell(url: urls[0], index: 0)
                        .frame(width: cellWidth, height: cellHeight)
                        .clipped()
                    imageCell(url: urls[1], index: 1)
                        .frame(width: cellWidth, height: cellHeight)
                        .clipped()
                }
                HStack(spacing: spacing) {
                    imageCell(url: urls[2], index: 2)
                        .frame(width: cellWidth, height: cellHeight)
                        .clipped()
                    imageCell(url: urls[3], index: 3)
                        .frame(width: cellWidth, height: cellHeight)
                        .clipped()
                }
            }
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
