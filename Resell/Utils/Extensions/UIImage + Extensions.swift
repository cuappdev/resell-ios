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
        return size.width / size.height
    }
}

