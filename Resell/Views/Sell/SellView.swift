//
//  SellView.swift
//  Resell
//
//  Created by Andrew Gao on 9/3/26.
//

import Flow
import PhotosUI
import SwiftUI

struct SellView: View {

    // MARK: - Properties

    @EnvironmentObject private var viewModel: NewListingViewModel

    @FocusState private var focusedField: Field?
    @State private var currentImageIndex = 0

    private enum Field {
        case title
        case price
        case description
    }

    /// Listing categories, in `Constants.filters` order. A nil color marks a
    /// pseudo-category ("Recent") that is not something you can list under.
    private let categoryOptions: [String] = Constants.filters.compactMap {
        $0.color == nil ? nil : $0.title
    }

    /// The backend category name differs from what reads well on the form.
    private let categoryDisplayNames = ["Handmade": "Homemade"]

    private let conditionOptions: [(label: String, value: String)] = [
        ("Brand New", "Never Used"),
        ("Gently Used", "Gently Used"),
        ("Used", "Worn"),
    ]

    // MARK: - UI

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                imagePicker
                primaryFields
                categorySection
                conditionSection
                descriptionField
                actionButtons
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Constants.Colors.white)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $viewModel.didShowPriceInput) {
            PriceInputView(
                price: $viewModel.priceText,
                isPresented: $viewModel.didShowPriceInput,
                titleText: "What price do you want to sell your product?"
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(25)
        }
        .photosPicker(
            isPresented: $viewModel.didShowPhotosPicker,
            selection: $viewModel.selectedItems,
            maxSelectionCount: viewModel.remainingImageSlots,
            matching: .images,
            photoLibrary: .shared()
        )
        .sheet(isPresented: $viewModel.didShowCamera) {
            ImagePicker(sourceType: .camera, selectedImages: $viewModel.selectedImages)
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
        .onChange(of: viewModel.selectedItems) { newItems in
            Task {
                await viewModel.updateListingImages(newItems: newItems)
            }
        }
        .onChange(of: viewModel.selectedImages.count) { imageCount in
            currentImageIndex = min(currentImageIndex, max(0, imageCount - 1))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sell")
                .font(Constants.Fonts.h1)
                .foregroundStyle(Constants.Colors.black)

            Text("Give the people what they want")
                .font(Constants.Fonts.body1)
                .foregroundStyle(Constants.Colors.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var imagePicker: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Constants.Colors.wash.opacity(0.6))

            if viewModel.selectedImages.isEmpty {
                emptyImagePicker
            } else {
                selectedImageCarousel
            }
        }
        .aspectRatio(385.0 / 439.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Constants.Colors.secondaryGray, lineWidth: 0.75)
        }
    }

    private var emptyImagePicker: some View {
        Button {
            focusedField = nil
            viewModel.didShowImageSourceDialog = true
        } label: {
            VStack(spacing: 16) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundStyle(Constants.Colors.black)

                Text("Add images to show off your listing")
                    .font(Constants.Fonts.subtitle1)
                    .foregroundStyle(Constants.Colors.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Constants.Colors.tertiaryGray)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Constants.Colors.black, lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }

    private var selectedImageCarousel: some View {
        ZStack {
            GeometryReader { proxy in
                TabView(selection: $currentImageIndex) {
                    ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                        Image(uiImage: viewModel.selectedImages[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .clipped()

            HStack {
                carouselButton(systemName: "chevron.left", direction: -1)

                Spacer()

                carouselButton(systemName: "chevron.right", direction: 1)
            }
            .padding(.horizontal, 8)

            VStack {
                HStack {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.removeImage(at: currentImageIndex)
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Constants.Colors.errorRed)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        viewModel.didShowImageSourceDialog = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Constants.Colors.black)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.remainingImageSlots == 0)
                }

                Spacer()

                Text("\(currentImageIndex + 1) / \(viewModel.selectedImages.count)")
                    .font(Constants.Fonts.subtitle1)
                    .foregroundStyle(Constants.Colors.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.55), in: Capsule())
            }
            .padding(12)
        }
    }

    private func carouselButton(systemName: String, direction: Int) -> some View {
        Button {
            let nextIndex = currentImageIndex + direction
            guard viewModel.selectedImages.indices.contains(nextIndex) else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                currentImageIndex = nextIndex
            }
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(Constants.Colors.white)
                .frame(width: 44, height: 60)
                .contentShape(Rectangle())
                .shadow(color: .black.opacity(0.35), radius: 2)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.selectedImages.indices.contains(currentImageIndex + direction))
        .opacity(viewModel.selectedImages.indices.contains(currentImageIndex + direction) ? 1 : 0)
    }

    private var primaryFields: some View {
        HStack(alignment: .top, spacing: 12) {
            listingField(
                label: "Item Name / Title",
                placeholder: "Something belongs here...",
                text: $viewModel.titleText,
                field: .title
            )

            priceField
        }
    }

    private var priceField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Price")
                .font(Constants.Fonts.body2)
                .foregroundStyle(Constants.Colors.black)

            Button {
                focusedField = nil
                viewModel.didShowPriceInput = true
            } label: {
                HStack(spacing: 6) {
                    Text("$")
                        .font(Constants.Fonts.body2)
                        .foregroundStyle(Constants.Colors.black)

                    Text(viewModel.priceText.isEmpty ? "1" : viewModel.priceText)
                        .font(Constants.Fonts.subtitle1)
                        .foregroundStyle(
                            viewModel.priceText.isEmpty
                                ? Constants.Colors.inactiveGray
                                : Constants.Colors.black
                        )

                    Spacer()
                }
                .padding(.horizontal, 10)
                .frame(width: 102, height: 36)
                .background(Constants.Colors.wash)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Constants.Colors.inactiveGray, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func listingField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        prefix: String? = nil,
        width: CGFloat? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Constants.Fonts.body2)
                .foregroundStyle(Constants.Colors.black)

            HStack(spacing: 6) {
                if let prefix {
                    Text(prefix)
                        .font(Constants.Fonts.body2)
                        .foregroundStyle(Constants.Colors.black)
                }

                TextField(placeholder, text: text)
                    .font(Constants.Fonts.subtitle1)
                    .foregroundStyle(Constants.Colors.black)
                    .focused($focusedField, equals: field)
                    .keyboardType(field == .price ? .decimalPad : .default)
            }
            .padding(.horizontal, 10)
            .frame(height: 36)
            .background(Constants.Colors.wash)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Constants.Colors.inactiveGray, lineWidth: 1)
            }
        }
        .frame(width: width)
        .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }

    private var categorySection: some View {
        formSection(title: "Category") {
            HFlow {
                ForEach(categoryOptions, id: \.self) { category in
                    selectionChip(
                        title: categoryDisplayNames[category] ?? category,
                        isSelected: viewModel.selectedFilter == category
                    ) {
                        viewModel.selectedFilter = category
                    }
                }
            }
        }
    }

    private var conditionSection: some View {
        formSection(title: "Condition") {
            HFlow {
                ForEach(conditionOptions.indices, id: \.self) { index in
                    let condition = conditionOptions[index]
                    selectionChip(
                        title: condition.label,
                        isSelected: viewModel.selectedCondition == condition.value
                    ) {
                        viewModel.selectedCondition = condition.value
                    }
                }
            }
        }
    }

    private func formSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Constants.Fonts.subtitle1)
                .foregroundStyle(Constants.Colors.black)

            Divider()
                .overlay(Constants.Colors.secondaryGray)

            content()
        }
    }

    private func selectionChip(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(Constants.Fonts.subtitle1)
                .foregroundStyle(
                    isSelected
                        ? Constants.Colors.resellPurple
                        : Constants.Colors.inactiveGray
                )
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    isSelected
                        ? Constants.Colors.resellPurple.opacity(0.15)
                        : Constants.Colors.white
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isSelected
                                ? Constants.Colors.resellPurple
                                : Constants.Colors.secondaryGray,
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(Constants.Fonts.subtitle1)
                .foregroundStyle(Constants.Colors.black)

            ZStack(alignment: .topLeading) {
                if viewModel.descriptionText.isEmpty {
                    Text("Details that someone buying this should know...")
                        .font(Constants.Fonts.subtitle1)
                        .foregroundStyle(Constants.Colors.inactiveGray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $viewModel.descriptionText)
                    .font(Constants.Fonts.subtitle1)
                    .foregroundStyle(Constants.Colors.black)
                    .focused($focusedField, equals: .description)
                    .scrollContentBackground(.hidden)
                    .padding(4)
                    .background(.clear)
            }
            .frame(minHeight: 80)
            .background(Constants.Colors.wash)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Constants.Colors.inactiveGray, lineWidth: 1)
            }
        }
    }

    private var actionButtons: some View {
        Button {
            focusedField = nil
            viewModel.createNewListing()
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Constants.Colors.white)
                } else {
                    Text("Publish Listing")
                }
            }
            .font(Constants.Fonts.title3)
            .foregroundStyle(Constants.Colors.white)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(Constants.Colors.tertiaryGray)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Constants.Colors.black, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!canPublish || viewModel.isLoading)
        .opacity(canPublish ? 1 : 0.45)
    }

    private var canPublish: Bool {
        !viewModel.selectedImages.isEmpty && viewModel.checkInputIsValid()
    }
}
