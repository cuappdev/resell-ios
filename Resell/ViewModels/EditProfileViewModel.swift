//
//  EditProfileViewModel.swift
//  Resell
//
//  Created by Richie Sun on 11/8/24.
//

import PhotosUI
import SwiftUI

@MainActor
class EditProfileViewModel: ObservableObject {

    // MARK: - Properties

    @Published var didShowPhotosPicker: Bool = false

    @Published var selectedImage: UIImage = UIImage(named: "emptyProfile")!
    @Published var selectedItem: PhotosPickerItem? = nil
    @Published var user: User? = nil

    @Published var username: String = ""
    @Published var venmoLink: String = ""
    @Published var bio: String = ""

    // MARK: - Functions

    func getUser() {
        Task {
            do {
                if let id = UserSessionManager.shared.userID {
                    user = try await NetworkManager.shared.getUserByID(id: id).user
                    username = user?.username ?? ""
                    venmoLink = user?.venmoHandle ?? ""
                    bio = user?.bio ?? ""

                    await decodeProfileImage(url: user?.photoUrl)
                } else if let googleID = UserSessionManager.shared.googleID {
                    user = try await NetworkManager.shared.getUserByGoogleID(googleID: googleID).user
                    username = user?.username ?? ""
                    venmoLink = user?.venmoHandle ?? ""
                    bio = user?.bio ?? ""

                    await decodeProfileImage(url: user?.photoUrl)
                } else {
                    UserSessionManager.shared.logger.error("Error in EditProfileViewModel.getUser: No userID or googleID found in UserSessionManager")
                }
            } catch {
                NetworkManager.shared.logger.error("Error in EditProfileViewModel.getUser: \(error.localizedDescription)")
            }
        }
    }

    func updateProfile() {
        
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

    private func decodeProfileImage(url: URL?) async {
        guard let url,
              let data = try? await URLSession.shared.data(from: url).0,
              let image = UIImage(data: data) else { return }

        selectedImage = image
    }

}
