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
    
    @Binding var isImageLoaded: Bool
    var isForYou: Bool? = nil
    let imageURL: URL?
    
    private let targetSize: CGSize = {
        let cellWidth = (UIScreen.main.bounds.width - 68) / 2
        return CGSize(width: cellWidth * 2, height: cellWidth * 2)
    }()
    
    var body: some View {
        KFImage(imageURL)
            .placeholder {
                ShimmerView()
            }
            .setProcessor(
                DownsamplingImageProcessor(size: targetSize)
            )
            .cacheOriginalImage()
            .fade(duration: 0.2)
            .onSuccess { _ in
                isImageLoaded = true
            }
            .onFailure { _ in
                isImageLoaded = false
            }
            .resizable()
            .aspectRatio(contentMode: .fill)
    }
}
