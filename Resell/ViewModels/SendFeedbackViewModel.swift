//
//  SendFeedbackViewModel.swift
//  Resell
//
//  Created by Richie Sun on 10/5/24.
//

import SwiftUI
import PhotosUI

class SendFeedbackViewModel: ObservableObject {

    // MARK: - Properties

    @Published var feedbackText: String = ""
    @Published var selectedImages: [UIImage] = []
    @Published var selectedItem: PhotosPickerItem? = nil
    @Published var photosPickerPresented: Bool = false

    // MARK: - Functions

    /// Updates selectedImages and feedback image gallery with the new PhotosPickerItem selected from the PhotosPicker
    func updateFeedbackItems(newItem: PhotosPickerItem?) async {
        if let newItem = newItem {
            if let data = try? await newItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                if selectedImages.count < 3 {
                    selectedImages.append(image)
                }
            }
        }
    }

}
