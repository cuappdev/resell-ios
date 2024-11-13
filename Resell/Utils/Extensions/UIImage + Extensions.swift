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

    func toBase64(compressionQuality: CGFloat = 1.0) -> String? {
        guard let imageData = self.jpegData(compressionQuality: compressionQuality) else { return nil }
        return "data:image/jpeg;base64,\(imageData.base64EncodedString())"
    }
}


