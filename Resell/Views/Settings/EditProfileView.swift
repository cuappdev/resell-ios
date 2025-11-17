//
//  EditProfileView.swift
//  Resell
//
//  Created by Richie Sun on 11/8/24.
//

import PhotosUI
import SwiftUI

struct EditProfileView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    @ObservedObject private var profileManager = CurrentUserProfileManager.shared
    
    @State private var editedUsername: String = ""
    @State private var editedBio: String = ""
    @State private var editedVenmo: String = ""
    @State private var editedProfilePic: UIImage = UIImage(named: "emptyProfile")!
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var didShowPhotosPicker: Bool = false

    // MARK: - UI

    var body: some View {
        VStack {
            profileImageView
                .padding(.bottom, 40)

            nameView

            editFieldsView

            Spacer()
        }
        .padding(.top, 40)
        .background(Constants.Colors.white)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Edit Profile")
                    .font(Constants.Fonts.h3)
                    .foregroundStyle(Constants.Colors.black)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    saveProfile()
                } label: {
                    Text("Save")
                        .font(Constants.Fonts.title1)
                        .foregroundStyle(Constants.Colors.resellPurple)
                }
            }
        }
        .loadingView(isLoading: profileManager.isLoading)
        .onAppear {
            loadCurrentValues()
        }
        .onChange(of: profileManager.isLoading) { newValue in
            if !newValue {
                router.popToRoot()
            }
        }
        .endEditingOnTap()
    }

    private var profileImageView: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: editedProfilePic)
                .resizable()
                .frame(width: 132, height: 132)
                .background(Constants.Colors.stroke)
                .clipShape(.circle)

            Button {
                didShowPhotosPicker = true
            } label: {
                Image("pencil.circle")
                    .shadow(radius: 2)
            }
            .buttonStyle(.borderless)
        }
        .photosPicker(isPresented: $didShowPhotosPicker, selection: $selectedItem, matching: .images, photoLibrary: .shared())
        .onChange(of: selectedItem) { newItem in
            Task {
                await updateProfileImage(newItem: newItem)
            }
        }
    }

    private var nameView: some View {
        VStack(spacing: 40) {
            HStack {
                Text("Name")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.black)

                Spacer()

                Text("\(profileManager.givenName) \(GoogleAuthManager.shared.user?.familyName ?? "")")
                    .font(Constants.Fonts.body1)
                    .foregroundStyle(Constants.Colors.black)
            }

            HStack {
                Text("NetID")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.black)

                Spacer()

                Text(GoogleAuthManager.shared.user?.netid ?? "")
                    .font(Constants.Fonts.body1)
                    .foregroundStyle(Constants.Colors.black)
            }
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
    }

    private var editFieldsView: some View {
        VStack(spacing: 40) {
            HStack(spacing: 60) {
                Text("Username")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.black)

                TextField("", text: $editedUsername)
                    .font(Constants.Fonts.body1)
                    .foregroundStyle(Constants.Colors.black)
                    .multilineTextAlignment(.trailing)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(Constants.Colors.wash)
                    .clipShape(.rect(cornerRadius: 10))
            }

            HStack(spacing: 60) {
                Text("Venmo Link")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.black)

                TextField("", text: $editedVenmo)
                    .font(Constants.Fonts.body1)
                    .foregroundStyle(Constants.Colors.black)
                    .multilineTextAlignment(.trailing)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(Constants.Colors.wash)
                    .clipShape(.rect(cornerRadius: 10))
            }

            HStack(alignment: .top, spacing: 60) {
                Text("Bio")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.black)

                TextEditor(text: $editedBio)
                    .font(Constants.Fonts.body1)
                    .foregroundColor(Constants.Colors.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .scrollContentBackground(.hidden)
                    .background(Constants.Colors.wash)
                    .cornerRadius(10)
                    .frame(height: 100)
                    .onChange(of: editedBio) { newText in
                        if newText.count > 1000 {
                            editedBio = String(newText.prefix(1000))
                        }
                    }
            }
        }
        .padding(.top, 40)
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
    }
    
    // MARK: - Functions
    
    private func loadCurrentValues() {
        // Load current profile data into editable state
        editedUsername = profileManager.username
        editedBio = profileManager.bio
        editedVenmo = profileManager.venmoHandle
        editedProfilePic = profileManager.profilePic
    }
    
    private func saveProfile() {
        Task {
            do {
                try await profileManager.updateProfile(
                    username: editedUsername,
                    bio: editedBio,
                    venmoHandle: editedVenmo,
                    profileImage: editedProfilePic
                )
            } catch {
                NetworkManager.shared.logger.error("Error in EditProfileView.saveProfile: \(error)")
            }
        }
    }
    
    private func updateProfileImage(newItem: PhotosPickerItem?) async {
        guard let newItem = newItem else { return }
        
        if let data = try? await newItem.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            editedProfilePic = image
        }
    }
}

#Preview {
    EditProfileView()
}
