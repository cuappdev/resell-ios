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

    @State private var didPresentProductDetails: Bool = false
    @State private var selectedItem: Item = Item.defaultItem

    let column1: [ProductGallery]
    let column2: [ProductGallery]

    // MARK: Init

    init(items: [Item]) {
        let (items1, items2): ([Item], [Item]) = items.splitIntoTwo()
        self.column1 = items1.map { ProductGallery(item: $0) }
        self.column2 = items2.map { ProductGallery(item: $0) }
    }

    // MARK: UI

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            HStack(alignment: .top, spacing: 20) {
                LazyVStack(spacing: 20) {
                    ForEach(column1) { item in
                        ProductGalleryCell(didPresentProductDetails: $didPresentProductDetails, selectedItem: $selectedItem, galleryItem: item)
                    }
                }

                LazyVStack(spacing: 20) {
                    ForEach(column2) { item in
                        ProductGalleryCell(didPresentProductDetails: $didPresentProductDetails, selectedItem: $selectedItem, galleryItem: item)
                    }
                }
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
        }
        .navigationDestination(isPresented: $didPresentProductDetails) {
            // TODO: - Change with backend logic
            ProductDetailsView(userIsSeller: false, item: selectedItem)
        }
        .onTapGesture {
            didPresentProductDetails = true
        }
    }
}

struct ProductGalleryCell: View {

    // MARK: Properties

    @Binding var didPresentProductDetails: Bool
    @Binding var selectedItem: Item

    let galleryItem: ProductGallery

    // MARK: UI

    var body: some View {
        VStack(spacing: 0) {
            Image(galleryItem.item.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: galleryItem.width, height: galleryItem.height)
                .clipped()
            HStack {
                Text(galleryItem.item.title)
                    .font(Constants.Fonts.title3)
                    .foregroundStyle(Constants.Colors.black)
                Spacer()
                Text("$\(galleryItem.item.price)")
                    .font(Constants.Fonts.title4)
                    .foregroundStyle(Constants.Colors.black)
            }
            .padding(8)
        }
        .clipped()
        .clipShape(.rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Constants.Colors.stroke, lineWidth: 1)
        }
        .onTapGesture {
            selectedItem = galleryItem.item
            didPresentProductDetails = true
        }
    }

}

struct ProductGallery: Identifiable {
    
    var id: UUID
    let aspectRatio: CGFloat
    let item: Item
    let width: CGFloat
    let height: CGFloat

    init(item: Item) {
        self.id = item.id
        self.item = item

        var imageRatio: CGFloat {
            guard let uiImage = UIImage(named: item.image) else {
                return 1.0
            }
            return uiImage.aspectRatio
        }

        self.aspectRatio = imageRatio
        self.width = (UIScreen.width - 68) / 2
        self.height = width / imageRatio
    }
    
}
