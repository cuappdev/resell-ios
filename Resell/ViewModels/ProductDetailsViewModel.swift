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
    @Published var images: [URL] = []

    @Published var isSaved: Bool = false
    @Published var maxDrag: CGFloat = UIScreen.height / 2
    @Published var maxImgRatio: CGFloat = 1.0
    @Published var item: Post?

    // MARK: - Functions

    func getPost(id: String) {
        Task {
            do {
                let postResponse = try await NetworkManager.shared.getPostByID(id: id)
                item = postResponse.post
                images = postResponse.post.images

                await calculateMaxImgRatio()
            } catch {
                NetworkManager.shared.logger.error("Error in ProductDetailsViewModel.getPost: \(error.localizedDescription)")
            }
        }
    }

    func updateItemSaved() {
        // TODO: Insert backend saveItem call
    }

    func changeItem() {
        // TODO: Backend Call to change item to similar item
    }

    private func calculateMaxImgRatio() async {
        var maxRatio = 0.0
        for imageUrl in images {
            guard let data = try? await URLSession.shared.data(from: imageUrl).0,
                  let image = UIImage(data: data) else { continue }

            let aspectRatio = image.aspectRatio

            maxRatio = max(maxRatio, aspectRatio)
        }

        withAnimation {
            maxImgRatio = maxRatio
        }
    }
}
