//
//  ProductsGallery.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import SwiftUI

/// Reusable gallery view used to display item listings
struct ProductsGalleryView: View {

    // MARK: Properties

    @State private var selectedItem: Post? = nil
    @EnvironmentObject var router: Router

    let items: [Post]
    let column1: [Post]
    let column2: [Post]

    let onScrollToBottom: (() -> Void)?

    // MARK: Init

    init(items: [Post], onScrollToBottom: (() -> Void)? = nil) {
        self.items = items
        let (items1, items2): ([Post], [Post]) = items.splitIntoTwo()
        self.column1 = items1
        self.column2 = items2
        self.onScrollToBottom = onScrollToBottom
    }

    // MARK: UI

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            LazyVStack(spacing: 10) {
                ForEach(column1, id: \.id) { post in
                    ProductGalleryCell(selectedItem: $selectedItem, post: post, savedCell: false)
                        .onAppear {
                            checkAndLoadMore(for: post)
                        }
                }
            }
            
            LazyVStack(spacing: 10) {
                ForEach(column2, id: \.id) { post in
                    ProductGalleryCell(selectedItem: $selectedItem, post: post, savedCell: false)
                        .onAppear {
                            checkAndLoadMore(for: post)
                        }
                }
            }
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .padding(.bottom, Constants.Spacing.horizontalPadding)
        .onChange(of: selectedItem) { item in
            guard let item else { return }
            navigateToProductDetails(post: item)
            selectedItem = nil
        }
    }
    
    // MARK: - Private Methods
    
    private func checkAndLoadMore(for post: Post) {
        guard let index = items.firstIndex(where: { $0.id == post.id }) else {
            return
        }
        
        let threshold = items.count - 5
        if index >= threshold {
            onScrollToBottom?()
        }
    }

    private func navigateToProductDetails(post: Post) {
        if let existingIndex = router.path.firstIndex(where: {
            if case .productDetails = $0 {
                return true
            }
            return false
        }) {
            router.path[existingIndex] = .productDetails(post)
            router.popTo(router.path[existingIndex])
        } else {
            router.push(.productDetails(post))
        }
    }
}

struct ProductGalleryCell: View {

    // MARK: Properties

    @Binding var selectedItem: Post?
    @ObservedObject private var homeViewModel = HomeViewModel.shared
    @State private var isImageLoaded: Bool = false
    @State private var imageAspectRatio: CGFloat?
    @State private var isSaved: Bool = false

    let post: Post
    let savedCell: Bool
    private let cellWidth = (UIScreen.width - 46) / 2

    // MARK: UI

    private var isSold: Bool {
        post.sold == true
    }

    /// Height/width ratio used while loading and as a fallback.
    private static let placeholderAspectRatio: CGFloat = 4.0 / 3.0

    private var imageHeight: CGFloat {
        let ratio = imageAspectRatio ?? Self.placeholderAspectRatio
        return cellWidth * ratio
    }

    private var categoryLabel: String {
        if let name = post.categories?.first?.name, !name.isEmpty {
            return name
        }
        if let category = post.category, !category.isEmpty {
            return category
        }
        return "Other"
    }

    private var conditionLabel: String? {
        guard let condition = post.condition, !condition.isEmpty else { return nil }
        return condition
    }

    private var detailsLabel: String {
        guard let conditionLabel else { return categoryLabel }
        return "\(categoryLabel) • \(conditionLabel)"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                selectedItem = post
            } label: {
                let url = URL(string: post.images.first ?? "")
                ZStack {
                    CachedImageView(
                        isImageLoaded: $isImageLoaded,
                        imageURL: url,
                        aspectRatio: $imageAspectRatio
                    )
                    .frame(width: cellWidth, height: imageHeight)
                    .clipped()

                    if isSold {
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: cellWidth, height: imageHeight)

                        Text("Item Sold")
                            .font(.custom("Rubik-Medium", size: 16))
                            .foregroundColor(.white)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)

            HStack(alignment: .top, spacing: 8) {
                infoButton
                VStack(alignment: .trailing, spacing: 2) {
                    priceLabel
                    if !savedCell { saveButton }
                }
            }
            .padding(8)
            .background(Constants.Colors.white)
        }
        .frame(width: cellWidth)
        .contentShape(.rect(cornerRadius: 8))
        .clipped()
        .clipShape(.rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Constants.Colors.stroke, lineWidth: 1)
        }
        .onAppear {
            loadSavedState()
        }
        .onReceive(homeViewModel.$savedItems) { savedItems in
            isSaved = savedItems.contains(where: { $0.id == post.id })
        }
        .onChange(of: post.id) { _ in
            imageAspectRatio = nil
            isImageLoaded = false
            loadSavedState()
        }
    }

    // MARK: - Private Methods

    private var infoButton: some View {
        Button {
            selectedItem = post
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(post.title)
                    .font(Constants.Fonts.title3)
                    .foregroundStyle(isSold ? Constants.Colors.secondaryGray : Constants.Colors.black)
                    .lineLimit(1)

                Text(detailsLabel)
                    .font(Constants.Fonts.subtitle1)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private var priceLabel: some View {
        Text("$\(post.originalPrice)")
            .font(Constants.Fonts.title3)
            .foregroundStyle(isSold ? Constants.Colors.secondaryGray : Constants.Colors.black)
            .lineLimit(1)
    }

    private var saveButton: some View {
        Button(action: toggleSave) {
            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Constants.Colors.black)
                .frame(width: 14, height: 14)
        }
        .buttonStyle(.plain)
    }

    private func loadSavedState() {
        if homeViewModel.savedItems.contains(where: { $0.id == post.id }) {
            isSaved = true
            return
        }

        // `savedItems` holds every saved post, so once it has loaded, absence is
        // an answer. Only fall back to a per-post request before that — otherwise
        // scrolling a feed fires one request per cell.
        guard !homeViewModel.hasLoadedSavedItems else {
            isSaved = false
            return
        }

        Task {
            let saved = (try? await NetworkManager.shared.postIsSaved(id: post.id))?.isSaved ?? false
            await MainActor.run {
                isSaved = saved
            }
        }
    }

    private func toggleSave() {
        let newState = !isSaved
        isSaved = newState

        Task {
            do {
                if newState {
                    _ = try await NetworkManager.shared.savePostByID(id: post.id)
                } else {
                    _ = try await NetworkManager.shared.unsavePostByID(id: post.id)
                }
                await homeViewModel.toggleLocalSaveStatus(for: post, isSaving: newState)
            } catch {
                await MainActor.run {
                    isSaved = !newState
                }
                NetworkManager.shared.logger.error("Error in ProductGalleryCell.toggleSave: \(error)")
            }
        }
    }
}
