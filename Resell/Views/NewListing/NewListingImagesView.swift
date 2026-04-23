//
//  NewListingImagesView.swift
//  Resell
//
//  Created by Richie Sun on 10/16/24.
//

import SwiftUI

struct NewListingImagesView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: NewListingViewModel
    @EnvironmentObject var mainViewModel: MainViewModel

    // MARK: - UI
    
    var body: some View {
        VStack {
            Spacer()

            if viewModel.selectedImages.isEmpty {
                VStack(alignment: .center) {
                    Text("Image Upload")
                        .font(Constants.Fonts.h2)
                        .foregroundStyle(Constants.Colors.black)
                        .padding(.bottom, 20)
                    Text("Add images of your item to get started with a new listing")
                        .font(Constants.Fonts.body1)
                        .foregroundStyle(Constants.Colors.secondaryGray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 33)
            } else {
                VStack(alignment: .leading) {
                    Text("Image Upload")
                        .font(Constants.Fonts.title1)
                        .foregroundStyle(Constants.Colors.black)
                        .padding(.horizontal, Constants.Spacing.horizontalPadding)
                        .padding(.bottom, 16)

                    PaginatedImageView(
                        images: $viewModel.selectedImages,
                        maxImages: 9,
                        onPickPhotoLibrary: { viewModel.didShowPhotosPicker = true },
                        onPickCamera: { viewModel.didShowCamera = true }
                    )
                        .padding(.horizontal, Constants.Spacing.horizontalPadding)
                }
                .padding(.top, 48)
            }

            Spacer()

            if viewModel.selectedImages.isEmpty {
                PurpleButton(text: "Add Images") {
                    viewModel.didShowImageSourceDialog = true
                }
                .confirmationDialog(
                    "Select Image Source",
                    isPresented: $viewModel.didShowImageSourceDialog,
                    titleVisibility: .visible
                ) {
                    Button("Photo Library") {
                        viewModel.didShowPhotosPicker = true
                    }
                    Button("Camera") {
                        viewModel.didShowCamera = true
                    }
                    Button("Cancel", role: .cancel) {}
                }
            } else {
                PurpleButton(text: "Continue") {
                    router.push(.newListingDetails)
                }
            }
        }
        .background(Constants.Colors.white)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("New Listing")
                    .font(Constants.Fonts.h3)
                    .foregroundStyle(Constants.Colors.black)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.pop()
                    viewModel.clear()

                    withAnimation {
                        mainViewModel.hidesTabBar = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .tint(Constants.Colors.black)
                }
            }
        }
        .photosPicker(isPresented: $viewModel.didShowPhotosPicker, selection: $viewModel.selectedItem, matching: .images, photoLibrary: .shared())
        .sheet(isPresented: $viewModel.didShowCamera) {
            ImagePicker(sourceType: .camera, selectedImages: $viewModel.selectedImages)
        }
        .onChange(of: viewModel.selectedItem) { newItem in
            Task {
                await viewModel.updateListingImage(newItem: newItem)
            }
        }
    }
}
