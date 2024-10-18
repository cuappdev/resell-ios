//
//  ProductDetailsViewModel.swift
//  Resell
//
//  Created by Richie Sun on 10/17/24.
//

import SwiftUI

@MainActor
class ProductDetailsViewModel: ObservableObject {

    // MARK: - Properties

    @Published var didShowOptionsMenu: Bool = false

    @Published var currentPage: Int = 0
    @Published var images: [UIImage] = [
        UIImage(named: "justin")!,
        UIImage(named: "justin")!,
        UIImage(named: "justin_long")!,
        UIImage(named: "justin")!
    ]
    @Published var maxDrag: CGFloat = UIScreen.height / 2
    @Published var maxImgRatio: CGFloat = 0.0

    // MARK: - Functions

    func deleteAction() {
        // MARK: - TODO Integrate backend delete post call
    }

    func reportAction() {

    }

    func shareAction() {

    }

    func calculateMaxImgRatio() {
        let maxAspectRatio = images.map { $0.aspectRatio }.max() ?? 1.0
        maxImgRatio = maxAspectRatio
    }

}
