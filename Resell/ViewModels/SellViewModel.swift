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

        enum SelectionField: String, Identifiable {
            case category = "Category"
            case condition = "Condition"
            case event = "Event"

            var id: Self { self }
        }

        // MARK: - Properties

        @Published var selectedImages: [UIImage] = []
        @Published var selectedItems: [PhotosPickerItem] = []

        @Published var isShowingImageSourceDialog = false
        @Published var isShowingPhotosPicker = false
        @Published var isShowingCamera = false

        @Published var title = ""
        @Published var price = "" {
            didSet {
                let sanitized = Self.sanitizedPrice(price)
                if sanitized != price { price = sanitized }
            }
        }
        @Published var description = ""
        @Published private(set) var category: String?
        @Published private(set) var condition: String?
        @Published private(set) var event: String?

        @Published var activeSelectionField: SelectionField?
        @Published private(set) var isPublishing = false
        @Published var isShowingPublishError = false
        @Published private(set) var didPublish = false

        private static let backendCategories = ["Sports & Outdoors": "Active"]
        private static let backendConditions = ["Used": "Worn"]

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

        var canPublish: Bool {
            !selectedImages.isEmpty
                && !title.cleaned().isEmpty
                && (Double(price) ?? 0) > 0
                && category != nil
                && condition != nil
                && !description.cleaned().isEmpty
                && !isPublishing
        }

        // MARK: - Functions

        func addPhotoTapped() {
            isShowingImageSourceDialog = true
        }

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

        func options(for field: SelectionField) -> [String] {
            switch field {
            case .category:
                Constants.Sell.categories
            case .condition:
                Constants.Sell.conditions
            case .event:
                Constants.eventSpaces.map(\.title)
            }
        }

        func selection(for field: SelectionField) -> String? {
            switch field {
            case .category:
                category
            case .condition:
                condition
            case .event:
                event
            }
        }

        func apply(_ value: String?, to field: SelectionField) {
            switch field {
            case .category:
                category = value
            case .condition:
                condition = value
            case .event:
                event = value
            }
            activeSelectionField = nil
        }

        func publish() async {
            guard canPublish else { return }
            guard let user = GoogleAuthManager.shared.user else {
                GoogleAuthManager.shared.logger.error("Error in SellView.ViewModel.publish: User not available.")
                isShowingPublishError = true
                return
            }

            isPublishing = true
            defer { isPublishing = false }

            do {
                _ = try await NetworkManager.shared.createPost(postBody: await postBody(userId: user.firebaseUid))
                NotificationCenter.default.post(name: Constants.Notifications.NewListingCreated, object: nil)
                resetForm()
                didPublish = true
            } catch {
                NetworkManager.shared.logger.error("Error in SellView.ViewModel.publish: \(error)")
                isShowingPublishError = true
            }
        }

        // MARK: - Private Methods

        private func postBody(userId: String) async -> PostBody {
            let images = selectedImages
            let imagesBase64 = await Task.detached {
                images.map { $0.resizedToMaxDimension(Constants.Sell.uploadImageMaxDimension).toBase64() ?? "" }
            }.value

            return PostBody(
                title: title.cleaned(),
                description: description.cleaned(),
                categories: category.map { [Self.backendCategories[$0] ?? $0] } ?? [],
                condition: condition.map { Self.backendConditions[$0] ?? $0 } ?? "",
                original_price: Double(price) ?? 0,
                imagesBase64: imagesBase64,
                userId: userId,
                eventTags: Constants.eventSpaces.first { $0.title == event }.map { [$0.tag] }
            )
        }

        private func resetForm() {
            selectedImages = []
            title = ""
            price = ""
            description = ""
            category = nil
            condition = nil
            event = nil
        }


        private static func sanitizedPrice(_ text: String) -> String {
            let parts = text.filter { $0.isNumber || $0 == "." }.split(separator: ".", omittingEmptySubsequences: false)
            guard let whole = parts.first else { return "" }
            guard parts.count > 1 else { return String(whole) }
            return "\(whole).\(parts[1].prefix(2))"
        }
    }
}
