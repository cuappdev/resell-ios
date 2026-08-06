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
    @State private var pendingProfilePic: UIImage?
    @State private var didShowImageCropper = false

    @FocusState private var focusedField: Field?

    enum Field {
        case username, venmo, bio
    }
    
    // MARK: - UI

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack {
                    profileImageView
                        .padding(.bottom, 40)
                    
                    nameView
                    
                    editFieldsView
                    
                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = nil
            }
            .scrollDismissesKeyboard(.immediately)
            
        }
        .padding(.top, 40)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton()
            }

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
        .fullScreenCover(isPresented: $didShowImageCropper) {
            if let pendingProfilePic {
                ProfileImageCropView(
                    image: pendingProfilePic,
                    onCancel: {
                        didShowImageCropper = false
                        self.pendingProfilePic = nil
                    },
                    onSave: { croppedImage in
                        editedProfilePic = croppedImage
                        didShowImageCropper = false
                        self.pendingProfilePic = nil
                    }
                )
            }
        }
        .onAppear {
            loadCurrentValues()
        }
    }

    private var profileImageView: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: editedProfilePic)
                .resizable()
                .scaledToFill()
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
                    .focused($focusedField, equals: .username)
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
                    .focused($focusedField, equals: .venmo)
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
                    .id("bioField")
                    .focused($focusedField, equals: .bio)
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
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    // MARK: - Functions
    
    private func loadCurrentValues() {
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
            pendingProfilePic = image
            didShowImageCropper = true
            selectedItem = nil
        }
    }
}

private struct ProfileImageCropView: View {
    let image: UIImage
    let onCancel: () -> Void
    let onSave: (UIImage) -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let availableWidth = max(proxy.size.width - 32, 1)
                let availableHeight = max(proxy.size.height * 0.58, 1)
                let cropSize = max(min(availableWidth, availableHeight), 1)

                VStack(spacing: 28) {
                    Spacer()

                    cropPreview(size: cropSize)

                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "minus.magnifyingglass")
                            Slider(
                                value: Binding(
                                    get: { scale },
                                    set: { newScale in
                                        scale = newScale
                                        offset = clampedOffset(
                                            offset,
                                            cropSize: cropSize,
                                            scale: newScale
                                        )
                                    }
                                ),
                                in: 1...4,
                                onEditingChanged: { isEditing in
                                    if !isEditing {
                                        lastScale = scale
                                        lastOffset = offset
                                    }
                                }
                            )
                            Image(systemName: "plus.magnifyingglass")
                        }
                        .foregroundStyle(Constants.Colors.black)

                        Text("Pinch to zoom and drag to reposition")
                            .font(Constants.Fonts.subtitle1)
                            .foregroundStyle(Constants.Colors.secondaryGray)
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Constants.Colors.white)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel", action: onCancel)
                    }

                    ToolbarItem(placement: .principal) {
                        Text("Adjust Photo")
                            .font(Constants.Fonts.title1)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Use Photo") {
                            onSave(croppedImage(cropSize: cropSize))
                        }
                        .font(Constants.Fonts.title2)
                    }
                }
            }
        }
    }

    private func cropPreview(size: CGFloat) -> some View {
        let imageWidth = max(image.size.width, 1)
        let imageHeight = max(image.size.height, 1)
        let baseScale = max(size / imageWidth, size / imageHeight)

        return Image(uiImage: image)
            .resizable()
            .frame(
                width: imageWidth * baseScale,
                height: imageHeight * baseScale
            )
            .scaleEffect(scale)
            .offset(offset)
            .frame(width: size, height: size)
            .background(Constants.Colors.black)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Constants.Colors.white, lineWidth: 2)
            }
            .contentShape(Circle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = clampedOffset(
                            CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            ),
                            cropSize: size,
                            scale: scale
                        )
                    }
                    .onEnded { _ in
                        lastOffset = offset
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = min(max(lastScale * value, 1), 4)
                        offset = clampedOffset(offset, cropSize: size, scale: scale)
                    }
                    .onEnded { _ in
                        lastScale = scale
                        lastOffset = offset
                    }
            )
    }

    private func clampedOffset(
        _ proposedOffset: CGSize,
        cropSize: CGFloat,
        scale: CGFloat
    ) -> CGSize {
        let imageWidth = max(image.size.width, 1)
        let imageHeight = max(image.size.height, 1)
        let baseScale = max(cropSize / imageWidth, cropSize / imageHeight)
        let displayedWidth = imageWidth * baseScale * scale
        let displayedHeight = imageHeight * baseScale * scale
        let maximumX = max(0, (displayedWidth - cropSize) / 2)
        let maximumY = max(0, (displayedHeight - cropSize) / 2)

        return CGSize(
            width: min(max(proposedOffset.width, -maximumX), maximumX),
            height: min(max(proposedOffset.height, -maximumY), maximumY)
        )
    }

    private func croppedImage(cropSize: CGFloat) -> UIImage {
        let normalizedImage = normalized(image)
        let imageSize = normalizedImage.size
        let baseScale = max(cropSize / imageSize.width, cropSize / imageSize.height)
        let displayScale = baseScale * scale
        let cropSide = cropSize / displayScale

        let cropRect = CGRect(
            x: min(
                max((imageSize.width - cropSide) / 2 - offset.width / displayScale, 0),
                imageSize.width - cropSide
            ),
            y: min(
                max((imageSize.height - cropSide) / 2 - offset.height / displayScale, 0),
                imageSize.height - cropSide
            ),
            width: cropSide,
            height: cropSide
        )

        guard let source = normalizedImage.cgImage else { return normalizedImage }
        let pixelScale = CGFloat(source.width) / imageSize.width
        let pixelRect = CGRect(
            x: cropRect.minX * pixelScale,
            y: cropRect.minY * pixelScale,
            width: cropRect.width * pixelScale,
            height: cropRect.height * pixelScale
        ).integral

        guard let cropped = source.cropping(to: pixelRect) else { return normalizedImage }
        return UIImage(cgImage: cropped, scale: normalizedImage.scale, orientation: .up)
    }

    private func normalized(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
}
