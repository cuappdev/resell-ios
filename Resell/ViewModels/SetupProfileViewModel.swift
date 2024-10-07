//
//  SetupProfileViewModel.swift
//  Resell
//
//  Created by Richie Sun on 9/16/24.
//

import PhotosUI
import SwiftUI

@MainActor
class SetupProfileViewModel: ObservableObject {

    // MARK: - Properties

    @Published var didAgreeWithEULA: Bool = false
    @Published var didShowPhotosPicker: Bool = false
    @Published var didShowWebView: Bool = false
    @Published var username: String = ""
    @Published var bio: String = ""

    @Published var selectedImage: UIImage = UIImage(named: "emptyProfile")!
    @Published var selectedItem: PhotosPickerItem? = nil

    // MARK: - Functions

    func checkInputIsValid() -> Bool {
        return !(username.cleaned().isEmpty || bio.cleaned().isEmpty) && didAgreeWithEULA
    }

    /// Updates selectedImage with user profile
    func updateUserProfile(newItem: PhotosPickerItem?) async {
        if let newItem = newItem {
            if let data = try? await newItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.selectedImage = image
                }
            }
        }
    }
}
