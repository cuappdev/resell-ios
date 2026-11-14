//
//  SellView.swift
//  Resell
//
//  Created by Ethan Chen on 10/28/26.
//

import PhotosUI
import SwiftUI

private enum SellLayout {
    static let photoSlotSpacing: CGFloat = 15
    static let formSpacing: CGFloat = 20
    static let fieldLabelSpacing: CGFloat = 12
    static let fieldHeight: CGFloat = 43
    static let fieldHorizontalPadding: CGFloat = 17
    static let pricePillWidth: CGFloat = 128
    static let pricePillVerticalPadding: CGFloat = 10
    static let descriptionLabelSpacing: CGFloat = 8
    static let descriptionHeight: CGFloat = 128
    static let descriptionCornerRadius: CGFloat = 10
    static let descriptionHorizontalPadding: CGFloat = 13
    static let descriptionVerticalPadding: CGFloat = 16
    /// TextEditor's built-in text inset, subtracted so typed text lines up with the placeholder.
    static let textEditorInset = CGSize(width: 5, height: 8)
    static let publishButtonWidth: CGFloat = 200
    static let publishButtonHeight: CGFloat = 49
}

struct SellView: View {

    // MARK: - Properties

    @StateObject private var viewModel = ViewModel()

    @State private var selectionSheetHeights: [ViewModel.SelectionField: CGFloat] = [:]

    @Environment(\.displayScale) private var displayScale

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
        .photosPicker(
            isPresented: $viewModel.isShowingPhotosPicker,
            selection: $viewModel.selectedItems,
            maxSelectionCount: viewModel.remainingImageSlots,
            matching: .images,
            photoLibrary: .shared()
        )
        .sheet(isPresented: $viewModel.isShowingCamera) {
            ImagePicker(sourceType: .camera, selectedImages: $viewModel.capturedImages)
        }
        .onChange(of: viewModel.selectedItems) { _ in Task { await viewModel.loadImages(displayScale: displayScale) } }
        .onChange(of: viewModel.capturedImages) { _ in Task { await viewModel.addCapturedImages() } }
        .background { selectionSheetSizer }
        .sheet(item: $viewModel.activeSelectionField) { field in
            selectionSheet(for: field)
        }
        .alert("Couldn't post your listing", isPresented: $viewModel.isShowingPublishError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Check your connection and try again.")
        }
    }

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
            fieldLabel("Photos")

            Spacer()

            Text(viewModel.photoCountText)
                .font(Constants.Fonts.title3)
                .foregroundStyle(Constants.Colors.mutedGray)
        }
    }

    private var photoStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SellLayout.photoSlotSpacing) {
                ForEach(viewModel.photoSlots.indices, id: \.self) { index in
                    photoSlot(at: index)
                }
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
            .padding(.vertical, PhotoSlotView.shadowRadius * 2)
        }
        .scrollDisabled(!viewModel.isPhotoStripScrollable)
        .padding(.horizontal, -Constants.Spacing.horizontalPadding)
        .padding(.vertical, -PhotoSlotView.shadowRadius * 2)
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

    private var formSection: some View {
        VStack(alignment: .leading, spacing: SellLayout.formSpacing) {
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
        VStack(alignment: .leading, spacing: SellLayout.fieldLabelSpacing) {
            fieldLabel("Title")

            TextField("", text: $viewModel.title)
                .font(Constants.Fonts.title2)
                .foregroundStyle(Constants.Colors.black)
                .overlay(alignment: .leading) {
                    if viewModel.title.isEmpty {
                        placeholder("What are you selling?", font: Constants.Fonts.title2)
                    }
                }
                .padding(.horizontal, SellLayout.fieldHorizontalPadding)
                .frame(height: SellLayout.fieldHeight)
                .background(Constants.Colors.wash, in: Capsule())
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
            .padding(.horizontal, SellLayout.fieldHorizontalPadding)
            .padding(.vertical, SellLayout.pricePillVerticalPadding)
            .frame(width: SellLayout.pricePillWidth)
            .background(Constants.Colors.wash, in: Capsule())
        }
        .frame(height: SellLayout.fieldHeight)
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: SellLayout.descriptionLabelSpacing) {
            fieldLabel("Description")

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.description)
                    .font(Constants.Fonts.title2)
                    .foregroundStyle(Constants.Colors.black)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, SellLayout.descriptionHorizontalPadding - SellLayout.textEditorInset.width)
                    .padding(.vertical, SellLayout.descriptionVerticalPadding - SellLayout.textEditorInset.height)

                if viewModel.description.isEmpty {
                    placeholder("Size, measurements, any flaws, where to pick up...", font: Constants.Fonts.title2)
                        .padding(.horizontal, SellLayout.descriptionHorizontalPadding)
                        .padding(.vertical, SellLayout.descriptionVerticalPadding)
                }
            }
            .frame(height: SellLayout.descriptionHeight)
            .background(Constants.Colors.wash, in: RoundedRectangle(cornerRadius: SellLayout.descriptionCornerRadius))
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

    private func selectionSheet(for field: ViewModel.SelectionField) -> SelectionSheet {
        SelectionSheet(
            title: field.rawValue,
            options: viewModel.options(for: field),
            selection: viewModel.selection(for: field),
            height: selectionSheetHeights[field] ?? 0
        ) { viewModel.apply($0, to: field) }
    }

    private var selectionSheetSizer: some View {
        ZStack {
            ForEach(ViewModel.SelectionField.allCases) { field in
                selectionSheet(for: field)
                    .fixedSize(horizontal: false, vertical: true)
                    .background {
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear { selectionSheetHeights[field] = proxy.size.height }
                        }
                    }
            }
        }
        .hidden()
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
                }
            }
            .frame(width: SellLayout.publishButtonWidth, height: SellLayout.publishButtonHeight)
        }
        .buttonStyle(.purpleCapsule)
        .disabled(!viewModel.canPublish)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SellView()
}

