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

    let column1: [Post]
    let column2: [Post]

    let onScrollToBottom: (() -> Void)?

    // MARK: Init

    init(items: [Post], onScrollToBottom: (() -> Void)? = nil) {
        let (items1, items2): ([Post], [Post]) = items.splitIntoTwo()
        self.column1 = items1
        self.column2 = items2
        self.onScrollToBottom = onScrollToBottom
    }

    // MARK: UI

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            HStack(alignment: .top, spacing: 20) {
                LazyVStack(spacing: 20) {
                    ForEach(column1, id: \.id) { post in
                        ProductGalleryCell(selectedItem: $selectedItem, post: post, savedCell: false)
//                            .onAppear {
//                                // pls fix me im dying 
//                                if post == column1.last  {
//                                    onScrollToBottom?()
//                                }
//                            }
                    }
                }

                LazyVStack(spacing: 20) {
                    ForEach(column2, id: \.id) { post in
                        ProductGalleryCell(selectedItem: $selectedItem, post: post, savedCell: false)
                    }
                }
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
            .padding(.bottom, Constants.Spacing.horizontalPadding)
        }
        .onChange(of: selectedItem) { item in
            if let selectedItem {
                navigateToProductDetails(post: selectedItem)
                self.selectedItem = nil
            }
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
    @State private var isImageLoaded: Bool = false

    let post: Post
    let savedCell : Bool
    private let cellWidth = (UIScreen.width - 68) / 2

    // MARK: UI

    var body: some View {
        VStack(spacing: 0) {
            let url = URL(string: post.images.first ?? "")
            CachedImageView(isImageLoaded: $isImageLoaded, imageURL: url)
                .frame(width: cellWidth, height: (savedCell ? cellWidth - 20 : cellWidth / 0.75))

            HStack {
                Text(post.title)
                    .font(Constants.Fonts.title3)
                    .foregroundStyle(Constants.Colors.black)
                Spacer()
                Text("$\(post.originalPrice)")
                    .font(Constants.Fonts.title4)
                    .foregroundStyle(Constants.Colors.black)
            }
            .padding(8)
            .background(Constants.Colors.white)
        }
        .frame(width: cellWidth)
        .clipped()
        .clipShape(.rect(cornerRadius: 8))
        .opacity(isImageLoaded ? 1 : 1)
        .onTapGesture {
            selectedItem = post
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Constants.Colors.stroke, lineWidth: 1)
        }
    }
}
