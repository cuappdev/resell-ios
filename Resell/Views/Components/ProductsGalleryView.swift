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
    @EnvironmentObject var router: Router  // Inject router

    let column1: [Post]
    let column2: [Post]

    // MARK: Init

    init(items: [Post]) {
        let (items1, items2): ([Post], [Post]) = items.splitIntoTwo()
        self.column1 = items1
        self.column2 = items2
    }

    // MARK: UI

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            HStack(alignment: .top, spacing: 20) {
                LazyVStack(spacing: 20) {
                    ForEach(column1) { post in
                        ProductGalleryCell(selectedItem: $selectedItem, post: post)
                    }
                }

                LazyVStack(spacing: 20) {
                    ForEach(column2) { post in
                        ProductGalleryCell(selectedItem: $selectedItem, post: post)
                    }
                }
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
            .padding(.top, Constants.Spacing.horizontalPadding)
        }
        .onChange(of: selectedItem) { item in
            if let selectedItem {
                router.push(.productDetails(selectedItem.id))
                self.selectedItem = nil
            }
        }
    }
}

struct ProductGalleryCell: View {

    // MARK: Properties

    @Binding var selectedItem: Post?
    @State private var isImageLoaded: Bool = false

    let post: Post

    private let cellWidth = (UIScreen.width - 68) / 2

    // MARK: UI

    var body: some View {
        VStack(spacing: 0) {
            CachedImageView(isImageLoaded: $isImageLoaded, imageURL: post.images.first)
                .frame(width: cellWidth, height: cellWidth / 0.75)
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
        }
        .frame(width: cellWidth)
        .clipped()
        .clipShape(.rect(cornerRadius: 8))
        .scaleEffect(isImageLoaded ? CGSize(width: 1, height: 1) : CGSize(width: 1, height: 0.9), anchor: .center)
        .onTapGesture {
            selectedItem = post
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Constants.Colors.stroke, lineWidth: 1)
                .scaleEffect(isImageLoaded ? CGSize(width: 1, height: 1) : CGSize(width: 1, height: 0.9), anchor: .center)
        }
    }
}
