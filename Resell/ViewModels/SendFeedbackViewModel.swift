//
//  SendFeedbackViewModel.swift
//  Resell
//
//  Created by Richie Sun on 10/5/24.
//

import SwiftUI
import PhotosUI

@MainActor
class SendFeedbackViewModel: ObservableObject {

    // MARK: - Properties

    @Published var didShowPopup: Bool = false
    @Published var didShowPhotosPicker: Bool = false

    @Published var isLoading: Bool = false

    @Published var feedbackText: String = ""

    @Published var selectedImages: [UIImage] = []
    @Published var selectedItem: PhotosPickerItem? = nil

    var selectedIndex: Int = 0

    // MARK: - Functions

    func checkInputIsValid() -> Bool {
        return !feedbackText.cleaned().isEmpty
    }

    /// Updates selectedImages and feedback image gallery with the new PhotosPickerItem selected from the PhotosPicker
    func updateFeedbackItems(newItem: PhotosPickerItem?) async {
        if let newItem = newItem {
            if let data = try? await newItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                if selectedImages.count < 3 {
                    DispatchQueue.main.async {
                        self.selectedImages.append(image)
                        self.selectedItem = nil
                    }
                }
            }
        }
    }

    func submitFeedback() {
        isLoading = true
        Task {
            defer { Task { @MainActor in withAnimation { isLoading = false } } }

            do {
                if let user = GoogleAuthManager.shared.user {
                    let imagesBase64 = selectedImages.map { $0.toBase64() ?? "" }
                    let feedbackBody = FeedbackBody(description: feedbackText, images: imagesBase64, userId: user.firebaseUid)
                    try await NetworkManager.shared.postFeedback(feedback: feedbackBody)
                } else {
                    GoogleAuthManager.shared.logger.error("Error in \(#file) \(#function): User not available.")
                }
            } catch {
                NetworkManager.shared.logger.error("Error in \(#file) \(#function): \(error)")
            }
        }
    }

    func togglePopup(isPresenting: Bool) {
        withAnimation {
            didShowPopup = isPresenting
        }
    }

    func removeImage() {
        selectedImages.remove(at: selectedIndex)
        togglePopup(isPresenting: false)
    }

}
