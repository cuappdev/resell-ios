//
//  UIImage + Extensions.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import SwiftUI
import UIKit

extension UIImage {

    var aspectRatio: CGFloat {
        return size.height / size.width
    }

    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }

    /// resize an Image so that the longest dimension is maxSize
    func resizedToMaxDimension(_ maxSize: CGFloat) -> UIImage {
        let largestDimension = max(size.width, size.height)
        if largestDimension <= maxSize {
            return self
        }

        // Calculate the scale factor
        let scaleFactor = maxSize / largestDimension

        // Calculate new dimensions
        let newWidth = size.width * scaleFactor
        let newHeight = size.height * scaleFactor
        let newSize = CGSize(width: newWidth, height: newHeight)

        // Create a new context to draw the scaled image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }

        // Draw the scaled image
        draw(in: CGRect(origin: .zero, size: newSize))

        // Get the new image from the context
        guard let scaledImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return self // Return original if scaling failed
        }

        return scaledImage
    }

    func toBase64(compressionQuality: CGFloat = 0.3) -> String? {
        guard let imageData = self.jpegData(compressionQuality: compressionQuality) else { return nil }
        return "data:image/jpeg;base64,\(imageData.base64EncodedString())"
    }

    /// Safe placeholder for an empty/loading user profile image.
    ///
    /// Previously the codebase scattered `UIImage(named: "emptyProfile")!`
    /// across view models and views. That force-unwrap is a launch-time crash
    /// hazard if the asset catalog drops `emptyProfile` (target membership
    /// changed, asset compilation failed for the device's iOS version, SVG
    /// rendering fallback issue, etc.). Use this single resolver so we always
    /// get a usable image: bundled asset → SF Symbol fallback → blank UIImage.
    ///
    /// Named `profilePlaceholder` rather than `emptyProfile` because Xcode 15+
    /// auto-synthesizes a `UIImage.emptyProfile` symbol from the asset
    /// catalog, which would collide with this extension.
    static let profilePlaceholder: UIImage = {
        if let asset = UIImage(named: "emptyProfile") {
            return asset
        }
        if let symbol = UIImage(systemName: "person.crop.circle") {
            return symbol
        }
        return UIImage()
    }()

    /// Whether the toolbar band is *clearly* dark enough for white icons.
    /// Mixed / mid-tone heroes (drinks, cafe walls, snow) stay on black.
    func prefersLightToolbarIcons(
        displayedIn containerSize: CGSize,
        darkThreshold: CGFloat = 0.38,
        requiredDarkFraction: CGFloat = 0.78
    ) -> Bool {
        guard let samples = toolbarBandLuminanceSamples(in: containerSize),
              !samples.isEmpty else {
            return false
        }
        let darkCount = samples.filter { $0 < darkThreshold }.count
        return CGFloat(darkCount) / CGFloat(samples.count) >= requiredDarkFraction
    }

    /// Grid of relative luminances (0 = black, 1 = white) from the visible
    /// top toolbar band after aspect-fill cropping and orientation fix.
    func toolbarBandLuminanceSamples(in containerSize: CGSize) -> [CGFloat]? {
        guard containerSize.width > 0, containerSize.height > 0,
              let upright = flattenedOrientation().cgImage else { return nil }

        let imageSize = CGSize(width: upright.width, height: upright.height)
        let visible = aspectFillVisibleRect(imageSize: imageSize, containerSize: containerSize)
        // Cover both leading + trailing toolbar items with a short top strip.
        let sample = CGRect(
            x: visible.minX,
            y: visible.minY,
            width: max(1, visible.width),
            height: max(1, visible.height * 0.14)
        ).integral

        guard let cropped = upright.cropping(to: sample) else { return nil }

        let gridWidth = 16
        let gridHeight = 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixels = [UInt8](repeating: 0, count: gridWidth * gridHeight * 4)
        guard let context = CGContext(
            data: &pixels,
            width: gridWidth,
            height: gridHeight,
            bitsPerComponent: 8,
            bytesPerRow: gridWidth * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .low
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: gridWidth, height: gridHeight))

        return stride(from: 0, to: pixels.count, by: 4).map { offset in
            let r = CGFloat(pixels[offset]) / 255
            let g = CGFloat(pixels[offset + 1]) / 255
            let b = CGFloat(pixels[offset + 2]) / 255
            return 0.2126 * r + 0.7152 * g + 0.0722 * b
        }
    }

    /// Draw the image upright so EXIF orientation doesn't shift the sampled corner.
    func flattenedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// Pixel rect of `imageSize` that remains visible when aspect-filled into `containerSize`.
    private func aspectFillVisibleRect(imageSize: CGSize, containerSize: CGSize) -> CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height

        if imageAspect > containerAspect {
            let visibleWidth = imageSize.height * containerAspect
            return CGRect(
                x: (imageSize.width - visibleWidth) / 2,
                y: 0,
                width: visibleWidth,
                height: imageSize.height
            )
        } else {
            let visibleHeight = imageSize.width / containerAspect
            return CGRect(
                x: 0,
                y: (imageSize.height - visibleHeight) / 2,
                width: imageSize.width,
                height: visibleHeight
            )
        }
    }
}


