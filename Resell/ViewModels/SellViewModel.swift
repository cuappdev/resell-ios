//
//  SellViewModel.swift
//  Resell
//
//  Created by Ethan Chen on 11/4/26.
//

import PhotosUI
import SwiftUI

extension SellView {

    @MainActor
    final class ViewModel: ObservableObject {

        // MARK: - Properties

        @Published var selectedImages: [UIImage] = []
        @Published var selectedItems: [PhotosPickerItem] = []

        @Published var isShowingImageSourceDialog = false
        @Published var isShowingPhotosPicker = false
        @Published var isShowingCamera = false

        var remainingImageSlots: Int {
            max(0, Constants.Sell.maxImages - selectedImages.count)
        }

        var photoCountText: String {
            "\(selectedImages.count)/\(Constants.Sell.maxImages)"
        }

        var isCameraAvailable: Bool {
            UIImagePickerController.isSourceTypeAvailable(.camera)
        }

        var photoSlots: [PhotoSlotView.Content] {
            guard !selectedImages.isEmpty else { return [.add, .empty] }
            let photos = selectedImages.map(PhotoSlotView.Content.photo)
            return remainingImageSlots > 0 ? photos + [.add] : photos
        }

        var isPhotoStripScrollable: Bool {
            !selectedImages.isEmpty
        }

        // MARK: - Functions

        func addPhotoTapped() {
            isShowingImageSourceDialog = true
        }

        /// Clears the picker selection afterward so picking the same photos again still triggers a load.
        func loadImages() async {
            guard !selectedItems.isEmpty, remainingImageSlots > 0 else {
                selectedItems = []
                return
            }

            var loaded: [UIImage] = []
            for item in selectedItems.prefix(remainingImageSlots) {
                do {
                    if let data = try await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        loaded.append(image)
                    }
                } catch {
                    NetworkManager.shared.logger.error("Error in SellView.ViewModel.loadImages: \(error)")
                }
            }

            selectedImages.append(contentsOf: loaded)
            selectedItems = []
        }

        func removeImage(at index: Int) {
            guard selectedImages.indices.contains(index) else { return }
            selectedImages.remove(at: index)
        }
    }
}
