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
    @Published var feedbackText: String = ""

    @Published var selectedImages: [UIImage] = []
    @Published var selectedItem: PhotosPickerItem? = nil

    var selectedIndex: Int = 0

    // MARK: - Functions

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
        // TODO: Integrate SendFeedback Backend Call
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
