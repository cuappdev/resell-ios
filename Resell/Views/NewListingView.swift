//
//  NewListingView.swift
//  Resell
//
//  Created by Richie Sun on 10/9/24.
//

import PhotosUI
import SwiftUI

struct NewListingView: View {

    // MARK: - Properties

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var mainViewModel: MainViewModel

    @State var didShowPhotosPicker: Bool = false
    @State var selectedImages: [UIImage] = []
    @State var selectedItem: PhotosPickerItem? = nil
    
    var selectedIndex: Int = 0

    // MARK: - UI

    var body: some View {
        NavigationStack {
            Spacer()

            if selectedImages.isEmpty {
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

                    PaginatedImageView(didShowPhotosPicker: $didShowPhotosPicker, images: $selectedImages, maxImages: 3)
                        .padding(.horizontal, Constants.Spacing.horizontalPadding)
                }
                .padding(.top, 48)
            }

            Spacer()

            PurpleButton(text: selectedImages.isEmpty ? "Add Images" : "Continue") {
                didShowPhotosPicker = true
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
        .photosPicker(isPresented: $didShowPhotosPicker, selection: $selectedItem, matching: .images, photoLibrary: .shared())
        .onChange(of: selectedItem) { newItem in
            Task {
                await updateListingImage(newItem: newItem)
            }
        }
    }

    // MARK: - Functions

    func updateListingImage(newItem: PhotosPickerItem?) async {
        if let newItem = newItem {
            if let data = try? await newItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                if selectedImages.count < 3 {
                    DispatchQueue.main.async {
                        selectedImages.append(image)
                        selectedItem = nil
                    }
                }
            }
        }
    }
}
