//
//  CachedImageView.swift
//  Resell
//
//  Created by Richie Sun on 11/4/24.
//

import Kingfisher
import SwiftUI

/// A reusable view that displays an image from a URL with caching support using Kingfisher.
struct CachedImageView: View {

    // MARK: - Properties

    @Binding var isImageLoaded: Bool

    let imageURL: URL?

    // MARK: - UI

    var body: some View {
        KFImage(imageURL)
            .placeholder {
                ShimmerView()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .onSuccess { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    isImageLoaded = true
                }
            }
            .fade(duration: 0.3)
            .scaleFactor(UIScreen.main.scale)
            .backgroundDecode()
            .cacheOriginalImage()
            .resizable()
            .aspectRatio(contentMode: .fill)
            .clipped()
    }
}
