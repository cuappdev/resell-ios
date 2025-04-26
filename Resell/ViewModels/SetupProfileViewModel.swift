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

    @Published var errorText: String = ""
    @Published var didAgreeWithEULA: Bool = false
    @Published var didPresentError: Bool = false
    @Published var didShowPhotosPicker: Bool = false
    @Published var didShowWebView: Bool = false
    @Published var isLoading: Bool = false

    @Published var username: String = ""
    @Published var bio: String = ""
    @Published var venmoHandle: String = ""

    @Published var selectedImage: UIImage? = nil
    @Published var selectedItem: PhotosPickerItem? = nil

    @Published var netid: String = ""
    @Published var givenName: String = ""
    @Published var familyName: String = ""
    @Published var email: String = ""
    @Published var googleID: String = ""

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

                    self.selectedImage = image.resizedToMaxDimension(512)
                }
            }
        }
    }

    func createNewUser() {
        isLoading = true

        if selectedImage == nil {
            presentError("Please select a profile picture.")
            return
        }

        Task {
            defer { Task { @MainActor in withAnimation { isLoading = false } } }

            do {
                if let imageBase64 = selectedImage?.resizedToMaxDimension(256).toBase64() {
                    let imageBody = ImageBody(imageBase64: imageBase64)
                    let imageUrl = try await NetworkManager.shared.uploadImage(image: imageBody).image

                    guard let fcmToken = FirebaseNotificationService.shared.fcmToken, let user = GoogleAuthManager.shared.user else {
                        return
                    }

                    let userBody = user.toCreateUserBody(username: username, bio: bio, venmoHandle: venmoHandle, imageUrl: imageUrl, fcmToken: fcmToken)
                    try await NetworkManager.shared.createUser(user: userBody)
                }
            } catch {
                if error as? ErrorResponse == ErrorResponse.usernameAlreadyExists {
                    presentError("That username is already taken.")
                }
                NetworkManager.shared.logger.error("Error in SetupProfileViewModel.createNewUser: \(error)")
            }
        }
    }

    func clear() {
        didAgreeWithEULA = false
        didShowPhotosPicker = false
        didShowWebView = false

        username = ""
        bio = ""
        venmoHandle = ""
        selectedImage = UIImage(named: "emptyProfile")!
        selectedItem = nil

        netid = ""
        givenName = ""
        familyName = ""
        email = ""
        googleID = ""
    }

    private func presentError(_ error: String) {
        errorText = error
        didPresentError = true
    }

}
