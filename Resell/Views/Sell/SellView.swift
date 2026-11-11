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
                formSection
                publishButton
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Constants.Colors.white)
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog(
            "Select Image Source",
            isPresented: $viewModel.isShowingImageSourceDialog,
            titleVisibility: .visible
        ) {
            imageSourceButtons
        }
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
        .sheet(item: $viewModel.activeSelectionField) { field in
            SelectionSheet(
                title: field.rawValue,
                options: viewModel.options(for: field),
                selection: viewModel.selection(for: field)
            ) { viewModel.apply($0, to: field) }
        }
        .alert("Couldn't post your listing", isPresented: $viewModel.isShowingPublishError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Check your connection and try again.")
        }
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
                    PhotoSlotView(
                        index: index,
                        content: viewModel.photoSlots[index],
                        onAdd: viewModel.addPhotoTapped,
                        onRemove: { viewModel.removeImage(at: index) }
                    )
                }
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
            .padding(.vertical, Constants.Sell.photoShadowRadius * 2)
        }
        .scrollDisabled(!viewModel.isPhotoStripScrollable)
        .padding(.horizontal, -Constants.Spacing.horizontalPadding)
        .padding(.vertical, -Constants.Sell.photoShadowRadius * 2)
    }

    @ViewBuilder
    private var imageSourceButtons: some View {
        Button("Photo Library") { viewModel.isShowingPhotosPicker = true }

        if viewModel.isCameraAvailable {
            Button("Camera") { viewModel.isShowingCamera = true }
        }

        Button("Cancel", role: .cancel) {}
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(alignment: .leading, spacing: Constants.Sell.formSpacing) {
            titleField
            divider
            priceRow
            divider
            selectionRow(.category, placeholder: "Choose")
            divider
            selectionRow(.condition, placeholder: "Choose")
            divider
            selectionRow(.event, placeholder: "None", isOptional: true)
            divider
            descriptionField
        }
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: Constants.Sell.fieldLabelSpacing) {
            fieldLabel("Title")

            TextField("", text: $viewModel.title)
                .font(Constants.Fonts.title2)
                .foregroundStyle(Constants.Colors.black)
                .overlay(alignment: .leading) {
                    if viewModel.title.isEmpty {
                        placeholder("What are you selling?", font: Constants.Fonts.title2)
                    }
                }
                .padding(.horizontal, Constants.Sell.fieldHorizontalPadding)
                .frame(height: Constants.Sell.fieldHeight)
                .background(Constants.Colors.wash)
                .clipShape(Capsule())
        }
    }

    private var priceRow: some View {
        HStack {
            fieldLabel("Price")

            Spacer()

            HStack {
                Text("$")
                    .font(Constants.Fonts.title2)
                    .foregroundStyle(Constants.Colors.black)

                TextField("", text: $viewModel.price)
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.black)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .overlay(alignment: .trailing) {
                        if viewModel.price.isEmpty {
                            placeholder("0.00", font: Constants.Fonts.title1)
                        }
                    }
            }
            .padding(.horizontal, Constants.Sell.fieldHorizontalPadding)
            .padding(.vertical, Constants.Sell.pricePillVerticalPadding)
            .frame(width: Constants.Sell.pricePillWidth)
            .background(Constants.Colors.wash)
            .clipShape(Capsule())
        }
        .frame(height: Constants.Sell.fieldHeight)
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: Constants.Sell.descriptionLabelSpacing) {
            fieldLabel("Description")

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.description)
                    .font(Constants.Fonts.title2)
                    .foregroundStyle(Constants.Colors.black)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, Constants.Sell.descriptionHorizontalPadding - Constants.Sell.textEditorInset.width)
                    .padding(.vertical, Constants.Sell.descriptionVerticalPadding - Constants.Sell.textEditorInset.height)

                if viewModel.description.isEmpty {
                    placeholder("Size, measurements, any flaws, where to pick up...", font: Constants.Fonts.title2)
                        .padding(.horizontal, Constants.Sell.descriptionHorizontalPadding)
                        .padding(.vertical, Constants.Sell.descriptionVerticalPadding)
                }
            }
            .frame(height: Constants.Sell.descriptionHeight)
            .background(Constants.Colors.wash)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Sell.descriptionCornerRadius))
        }
    }

    private func selectionRow(_ field: ViewModel.SelectionField, placeholder: String, isOptional: Bool = false) -> some View {
        SellFormRow(
            label: field.rawValue,
            value: viewModel.selection(for: field),
            placeholder: placeholder,
            isOptional: isOptional,
            action: { viewModel.activeSelectionField = field }
        )
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(Constants.Fonts.h3)
            .foregroundStyle(Constants.Colors.black)
    }

    private func placeholder(_ text: String, font: Font) -> some View {
        Text(text)
            .font(font)
            .foregroundStyle(Constants.Colors.mutedGray)
            .allowsHitTesting(false)
    }

    private var divider: some View {
        Rectangle()
            .fill(Constants.Colors.stroke)
            .frame(height: 1)
    }

    // MARK: - Publish

    private var publishButton: some View {
        Button {
            Task { await viewModel.publish() }
        } label: {
            ZStack {
                if viewModel.isPublishing {
                    ProgressView()
                        .tint(Constants.Colors.white)
                } else {
                    Text("Publish")
                        .font(Constants.Fonts.title1)
                        .foregroundStyle(Constants.Colors.white)
                }
            }
            .frame(width: Constants.Sell.publishButtonWidth, height: Constants.Sell.publishButtonHeight)
            .background(Constants.Colors.resellPurple)
            .clipShape(Capsule())
            .opacity(viewModel.canPublish || viewModel.isPublishing ? 1 : Constants.Sell.disabledOpacity)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canPublish)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SellView()
}
