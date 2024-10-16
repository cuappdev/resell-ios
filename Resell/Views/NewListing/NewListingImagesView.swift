//
//  NewListingImagesView.swift
//  Resell
//
//  Created by Richie Sun on 10/16/24.
//

import SwiftUI

struct NewListingImagesView: View {

    // MARK: - Properties

    @Environment(\.dismiss) var dismiss
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

                    PaginatedImageView(didShowActionSheet: $viewModel.didShowActionSheet, images: $viewModel.selectedImages, maxImages: 9)
                        .padding(.horizontal, Constants.Spacing.horizontalPadding)
                }
                .padding(.top, 48)
            }

            Spacer()

            if viewModel.selectedImages.isEmpty {
                PurpleButton(text: "Add Images") {
                    viewModel.didShowActionSheet = true
                }
            } else {
                PurpleButton(text: "Continue") {
                    withAnimation {
                        viewModel.isDetailsView = true
                    }
                }
            }
        }
        .background(Constants.Colors.white)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("New Listing")
                    .font(Constants.Fonts.h3)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
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
        .onAppear {
            withAnimation {
                mainViewModel.hidesTabBar = true
            }
        }
        .actionSheet(isPresented: $viewModel.didShowActionSheet) {
            ActionSheet(
                title: Text("Select Image Source"),
                buttons: [
                    .default(Text("Photo Library")) {
                        viewModel.didShowPhotosPicker = true
                    },
                    .default(Text("Camera")) {
                        viewModel.didShowCamera = true
                    },
                    .cancel()
                ]
            )
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
