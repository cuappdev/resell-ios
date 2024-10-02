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
    @Published var didShowWebView: Bool = false
    @Published var username: String = ""
    @Published var bio: String = ""

    @Published var imageSelection: PhotosPickerItem? = nil {
        didSet {
            if let imageSelection {
                loadTransferable(from: imageSelection)
            }
        }
    }

    var image: Image = Image("emptyProfile")

    // MARK: - Functions

    func checkInputIsValid() -> Bool {
        return !(username.cleaned().isEmpty || bio.cleaned().isEmpty) && didAgreeWithEULA
    }

    private func loadTransferable(from imageSelection: PhotosPickerItem) {
        imageSelection.loadTransferable(type: Image.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                case .success(let profileImage?):
                    self.image = profileImage
                case .success(nil):
                    // Error action
                    print("bruh")
                case .failure(let error):
                    // Error action
                    print("bruh2")
                }
            }
        }
    }

}
