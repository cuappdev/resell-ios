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
        UIImage(named: "justin")!,
        UIImage(named: "tall_image")!
    ]
    @Published var isSaved: Bool = false
    @Published var maxDrag: CGFloat = UIScreen.height / 2
    @Published var maxImgRatio: CGFloat = 0.0

    // MARK: - Functions

    func getItem() {
        // TODO: Backend get Item Call
    }

    func updateItemSaved() {
        // TODO: Insert backend saveItem call
    }

    func changeItem() {
        // TODO: Backend Call to change item to similar item
    }

    func calculateMaxImgRatio() {
        let maxAspectRatio = images.map { $0.aspectRatio }.max() ?? 1.0
        maxImgRatio = maxAspectRatio
    }

}
