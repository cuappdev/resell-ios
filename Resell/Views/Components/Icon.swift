//
//  Icon.swift
//  Resell
//
//  Created by Richie Sun on 9/23/24.
//

import SwiftUI

/// 24 x 24 icon with customizable color
struct Icon: View {

    // MARK: - Properties

    var image: String

    // MARK: UI

    var body: some View {
        Image(image)
            .resizable()
            .scaledToFill()
            .frame(width: 24, height: 24)
    }
    
}
