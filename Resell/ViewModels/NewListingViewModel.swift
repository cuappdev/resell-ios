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

    @Published var didShowImageSourceDialog: Bool = false
    @Published var didShowCamera: Bool = false
    @Published var didShowPhotosPicker: Bool = false
    @Published var isLoading: Bool = false
    @Published var selectedImages: [UIImage] = []
    @Published var selectedItem: PhotosPickerItem? = nil
    @Published var didShowPriceInput: Bool = false
    @Published var descriptionText: String = ""
    @Published var priceText: String = ""
    @Published var selectedFilter: String = "Clothing"
    @Published var selectedCondition: String = "Never Used"
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
            isLoading = true
            
            Task {
                defer { Task { @MainActor in withAnimation { isLoading = false } } }

                do {
                    if let user = GoogleAuthManager.shared.user {
                        
                        let imagesToProcess = selectedImages

                        let imagesBase64: [String] = await Task.detached {
                            return imagesToProcess.map { image in
                                image.resizedToMaxDimension(512).toBase64() ?? ""
                            }
                        }.value
                        
                        
                        let postBody = PostBody(title: titleText, description: descriptionText, categories: [selectedFilter], condition: selectedCondition, original_price: Double(priceText) ?? 0, imagesBase64: imagesBase64, userId: user.firebaseUid)
                        
                        let _ = try await NetworkManager.shared.createPost(postBody: postBody)
                        
                        NotificationCenter.default.post(name: Constants.Notifications.NewListingCreated, object: nil)
                        
                        clear()
                    } else {
                        GoogleAuthManager.shared.logger.error("Error in \(#file) \(#function): User not available.")
                        clear()
                    }
                } catch {
                    NetworkManager.shared.logger.error("Error in NewListingViewModel.createNewListing: \(error)")
                    clear()
                }
            }
        }

    func clear() {
        didShowImageSourceDialog = false
        didShowCamera = false
        didShowPhotosPicker = false
        selectedImages = []
        selectedItem = nil
        didShowPriceInput = false
        descriptionText = ""
        priceText = ""
        selectedFilter = "Clothing"
        selectedCondition = "Never Worn"
        isLoading = false
    }
}
