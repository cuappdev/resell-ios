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
}


