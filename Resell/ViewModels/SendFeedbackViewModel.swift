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
        Task {
            isLoading = true

            do {
                if let userID = UserSessionManager.shared.userID {
                    let imagesBase64 = selectedImages.map { $0.toBase64() ?? "" }
                    let feedbackBody = FeedbackBody(description: feedbackText, images: imagesBase64, userId: userID)
                    try await NetworkManager.shared.postFeedback(feedback: feedbackBody)
                } else {
                    UserSessionManager.shared.logger.error("Error in SendFeedbackViewModel.submitFeedback: userID not found")
                }

                withAnimation { isLoading = false }
            } catch {
                NetworkManager.shared.logger.error("Error in SendFeedbackViewModel.submitFeedback: \(error)")
                withAnimation { isLoading = false }
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
