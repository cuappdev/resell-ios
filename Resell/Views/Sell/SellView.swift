//
//  SellView.swift
//  Resell
//
//  Created by Ethan Chen on 10/28/26.
//

import PhotosUI
import SwiftUI

struct SellView: View {

    // MARK: - Properties

    @StateObject private var viewModel = ViewModel()

    // MARK: - UI

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                photosSection
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
            .padding(.vertical, 12)
        }
        .background(Constants.Colors.white)
        .toolbar(.hidden, for: .navigationBar)
        .photosPicker(
            isPresented: $viewModel.isShowingPhotosPicker,
            selection: $viewModel.selectedItems,
            maxSelectionCount: viewModel.remainingImageSlots,
            matching: .images,
            photoLibrary: .shared()
        )
        .sheet(isPresented: $viewModel.isShowingCamera) {
            ImagePicker(sourceType: .camera, selectedImages: $viewModel.selectedImages)
        }
        .onChange(of: viewModel.selectedItems) { _ in Task { await viewModel.loadImages() } }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sell")
                .font(Constants.Fonts.h1)
                .foregroundStyle(Constants.Colors.black)

            Text("Give the people what they want")
                .font(Constants.Fonts.h3)
                .foregroundStyle(Constants.Colors.mutedGray)
        }
    }

    // MARK: - Photos

    private var photosSection: some View {
        VStack(spacing: 12) {
            photosTitleRow
            photoStrip

            Text("Start with your best shot")
                .font(Constants.Fonts.title3)
                .foregroundStyle(Constants.Colors.mutedGray)
        }
    }

    private var photosTitleRow: some View {
        HStack {
            Text("Photos")
                .font(Constants.Fonts.h3)
                .foregroundStyle(Constants.Colors.black)

            Spacer()

            Text(viewModel.photoCountText)
                .font(Constants.Fonts.title3)
                .foregroundStyle(Constants.Colors.mutedGray)
        }
    }

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.Sell.photoSlotSpacing) {
                ForEach(viewModel.photoSlots.indices, id: \.self) { index in
                    photoSlot(at: index)
                }
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
            .padding(.vertical, Constants.Sell.photoShadowRadius * 2)
        }
        .scrollDisabled(!viewModel.isPhotoStripScrollable)
        .padding(.horizontal, -Constants.Spacing.horizontalPadding)
        .padding(.vertical, -Constants.Sell.photoShadowRadius * 2)
    }

    /// The image source dialog hangs off the Add card so iOS anchors it there.
    @ViewBuilder
    private func photoSlot(at index: Int) -> some View {
        let content = viewModel.photoSlots[index]
        let slot = PhotoSlotView(
            index: index,
            content: content,
            onAdd: viewModel.addPhotoTapped,
            onRemove: { viewModel.removeImage(at: index) }
        )

        if content == .add {
            slot.confirmationDialog(
                "Select Image Source",
                isPresented: $viewModel.isShowingImageSourceDialog,
                titleVisibility: .visible
            ) {
                imageSourceButtons
            }
        } else {
            slot
        }
    }

    @ViewBuilder
    private var imageSourceButtons: some View {
        Button("Photo Library") { viewModel.isShowingPhotosPicker = true }

        if viewModel.isCameraAvailable {
            Button("Camera") { viewModel.isShowingCamera = true }
        }

        Button("Cancel", role: .cancel) {}
    }
}

#Preview {
    SellView()
}
