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

        enum SelectionField: String, CaseIterable, Identifiable {
            case category = "Category"
            case condition = "Condition"
            case event = "Event"

            var id: Self { self }
        }

        @Published var selectedImages: [UIImage] = []
        @Published var selectedItems: [PhotosPickerItem] = []
        @Published var capturedImages: [UIImage] = []

        @Published var isShowingImageSourceDialog = false
        @Published var isShowingPhotosPicker = false
        @Published var isShowingCamera = false

        @Published var title = ""
        @Published var price = ""
        @Published var description = ""
        @Published private(set) var category: String?
        @Published private(set) var condition: String?
        @Published private(set) var event: String?

        @Published var activeSelectionField: SelectionField?
        @Published private(set) var isPublishing = false
        @Published var isShowingPublishError = false

        private static let maxImages = 8
        private static let uploadImageMaxDimension: CGFloat = 512
        private static let categories = ["Clothing", "Books", "School", "Electronics", "Household", "Sports & Outdoors", "Other"]
        private static let conditions = ["Gently Used", "Used", "Never Used"]
        private static let backendCategories = ["Sports & Outdoors": "Active"]
        private static let backendConditions = ["Used": "Worn"]

        var remainingImageSlots: Int {
            max(0, Self.maxImages - selectedImages.count)
        }

        var photoCountText: String {
            "\(selectedImages.count)/\(Self.maxImages)"
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
        }

        func addPhotoTapped() {
            isShowingImageSourceDialog = true
        }

        /// Decodes the photos picked from the library straight to upload size, so the strip never
        /// holds full-resolution bitmaps.
        func loadImages(displayScale: CGFloat) async {
            guard !selectedItems.isEmpty, remainingImageSlots > 0 else {
                selectedItems = []
                return
            }

            let maxDimension = Self.uploadImageMaxDimension
            var loaded: [UIImage] = []
            for item in selectedItems.prefix(remainingImageSlots) {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                    let image = await Task.detached {
                        UIImage.downsampled(from: data, maxDimension: maxDimension, scale: displayScale)
                    }.value
                    if let image { loaded.append(image) }
                } catch {
                    NetworkManager.shared.logger.error("Error in SellView.ViewModel.loadImages: \(error)")
                }
            }

            selectedImages.append(contentsOf: loaded.prefix(remainingImageSlots))
            selectedItems = []
        }

        /// Shrinks camera captures to upload size before they join the strip.
        func addCapturedImages() async {
            guard !capturedImages.isEmpty else { return }
            let captured = capturedImages
            capturedImages = []

            let maxDimension = Self.uploadImageMaxDimension
            let resized = await Task.detached {
                captured.map { $0.resizedToMaxDimension(maxDimension) }
            }.value
            selectedImages.append(contentsOf: resized.prefix(remainingImageSlots))
        }

        func removeImage(at index: Int) {
            guard selectedImages.indices.contains(index) else { return }
            selectedImages.remove(at: index)
        }

        func options(for field: SelectionField) -> [String] {
            switch field {
            case .category:
                Self.categories
            case .condition:
                Self.conditions
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

        /// Keeps the typed price a plain dollar amount: digits with at most two decimal places, the
        /// region's decimal separator read as ".", and no leading zeros.
        func normalizePrice() {
            let normalized = Self.normalizedPrice(price)
            if normalized != price { price = normalized }
        }

        func publish() async {
            guard canPublish, !isPublishing else { return }
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
            } catch {
                NetworkManager.shared.logger.error("Error in SellView.ViewModel.publish: \(error)")
                isShowingPublishError = true
            }
        }

        private func postBody(userId: String) async -> PostBody {
            let images = selectedImages
            let imagesBase64 = await Task.detached {
                images.map { $0.toBase64() ?? "" }
            }.value

            return PostBody(
                title: title.cleaned(),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
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

        private static func normalizedPrice(_ text: String) -> String {
            let parts = text
                .replacingOccurrences(of: Locale.current.decimalSeparator ?? ".", with: ".")
                .split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
                .map { $0.compactMap(\.wholeNumberValue).map(String.init).joined() }
            let hasDecimalPoint = parts.count > 1
            var whole = String(parts[0].drop { $0 == "0" })
            if whole.isEmpty && (hasDecimalPoint || !parts[0].isEmpty) { whole = "0" }
            return hasDecimalPoint ? "\(whole).\(parts[1].prefix(2))" : whole
        }
    }
}
