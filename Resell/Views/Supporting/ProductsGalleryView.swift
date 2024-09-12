//
//  ProductsGallery.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import SwiftUI

struct ProductsGalleryView: View {

    // MARK: Properties

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
        HStack(alignment: .top, spacing: 20) {
            LazyVStack(spacing: 20) {
                ForEach(column1) { item in
                    ProductGalleryCell(galleryItem: item)
                }
            }
            .background(.blue)

            LazyVStack(spacing: 20) {
                ForEach(column2) { item in
                    ProductGalleryCell(galleryItem: item)
                }
            }
            .background(.red)
        }
        .padding(.horizontal, 24)
    }
}

struct ProductGalleryCell: View {

    // MARK: Properties

    let galleryItem: ProductGallery

    // MARK: UI

    var body: some View {
        VStack {
            Image(galleryItem.item.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
            Text(galleryItem.item.image)
                .font(.caption)
                .padding(.top, 5)
        }
        .background(.green)
        .frame(width: galleryItem.width, height: galleryItem.height)
        .clipped()
        .cornerRadius(8)
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
