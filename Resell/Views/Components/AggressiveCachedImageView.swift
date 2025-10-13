//
//  AggressiveCachedImageView.swift
//  Resell
//
//  Created by Charles Liggins on 10/13/25.
//
import SwiftUI
import Kingfisher

struct AggressiveCachedImageView: View {
    
    @Binding var isImageLoaded: Bool
    @State private var shouldLoad: Bool = false
    
    let imageURL: URL?
    
    private let targetSize: CGSize = {
        let cellWidth = (UIScreen.main.bounds.width - 68) / 2
        return CGSize(width: cellWidth * 2, height: cellWidth * 2)
    }()
    
    var body: some View {
        Group {
            if shouldLoad {
                KFImage(imageURL)
                    .placeholder {
                        ShimmerView()
                    }
                    .setProcessor(
                        DownsamplingImageProcessor(size: targetSize)
                            |> RoundCornerImageProcessor(cornerRadius: 8)
                    )
                    .cacheMemoryOnly()
                    .fade(duration: 0.2)
                    .onSuccess { _ in
                        isImageLoaded = true
                    }
                    .onFailure { _ in
                        isImageLoaded = false
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ShimmerView()
                    .onAppear {
                        // Delay image loading slightly to prioritize visible items
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            shouldLoad = true
                       // }
                    }
            }
        }
        .onDisappear {
            // Cancel any pending loads when scrolling away
            if let url = imageURL {
                KingfisherManager.shared.downloader.cancel(url: url)
            }
            shouldLoad = false
        }
    }
}
