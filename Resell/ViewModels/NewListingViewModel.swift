//
//  NewListingViewModel.swift
//  Resell
//
//  Created by Richie Sun on 10/16/24.
//

import PhotosUI
import SwiftUI

@MainActor
class NewListingViewModel: ObservableObject {
    
    // MARK: - Properties

    @Published var isDetailsView: Bool = false

    @Published var didShowActionSheet: Bool = false
    @Published var didShowCamera: Bool = false
    @Published var didShowPhotosPicker: Bool = false

    @Published var selectedImages: [UIImage] = []
    @Published var selectedItem: PhotosPickerItem? = nil

    @Published var didShowPriceInput: Bool = false

    @Published var descriptionText: String = ""
    @Published var priceText: String = ""
    @Published var selectedFilter: String = "Clothing"
    @Published var titleText: String = ""

    // MARK: - Functions

    func checkInputIsValid() -> Bool {
        return !(descriptionText.cleaned().isEmpty || priceText.cleaned().isEmpty || titleText.cleaned().isEmpty)
    }

    func updateListingImage(newItem: PhotosPickerItem?) async {
        if let newItem = newItem {
            if let data = try? await newItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                if selectedImages.count < 7 {
                    DispatchQueue.main.async {
                        self.selectedImages.append(image)
                        self.selectedItem = nil
                    }
                }
            }
        }
    }

    func createNewListing() {
        // TODO: Backend Call
    }
}
