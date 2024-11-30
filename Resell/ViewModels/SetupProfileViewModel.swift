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
    @Published var isLoading: Bool = false

    @Published var username: String = ""
    @Published var bio: String = ""
    @Published var venmoHandle: String = ""

    @Published var selectedImage: UIImage = UIImage(named: "emptyProfile")!
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
                    self.selectedImage = image
                }
            }
        }
    }

    func createNewUser() {
        Task {
            isLoading = true
            
            do {
                if let imageBase64 = selectedImage.toBase64() {
                    let user = CreateUserBody(username: username.cleaned(), netid: netid, givenName: givenName, familyName: familyName, photoUrl: imageBase64, email: email, googleID: googleID, bio: bio.cleaned())
                    try await NetworkManager.shared.createUser(user: user)

                    try await FirestoreManager.shared.saveOnboarded(userEmail: email)
                    try await FirestoreManager.shared.saveVenmo(userEmail: email, venmo: venmoHandle)
                    loginUser(id: googleID)
                } else {
                    // TODO: Present Toast Error
                }

                withAnimation { isLoading = false }
            } catch {
                NetworkManager.shared.logger.error("Error in SetupProfileViewModel.createNewUser: \(error.localizedDescription)")
                withAnimation { isLoading = false }
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

    private func loginUser(id: String) {
        Task {
            do {
                let user = try await NetworkManager.shared.getUserByGoogleID(googleID: id).user
                let userSession = try await NetworkManager.shared.getUserSession(id: user.id).sessions.first

                UserSessionManager.shared.accessToken = userSession?.accessToken
                UserSessionManager.shared.googleID = id
                UserSessionManager.shared.userID = user.id
                UserSessionManager.shared.email = user.email
                UserSessionManager.shared.profileURL = user.photoUrl
                UserSessionManager.shared.name = "\(user.givenName) \(user.familyName)"
            } catch {
                NetworkManager.shared.logger.error("Error in LoginViewModel.getUserSession: \(error)")
            }
        }
    }

}
