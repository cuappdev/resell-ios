//
//  PaginatedImageView.swift
//  Resell
//
//  Created by Richie Sun on 10/14/24.
//

import SwiftUI

/// Multi-item paginated image view, displaying multiple images, one per page
struct PaginatedImageView: View {

    // MARK: - Properties

    @Binding var didShowPhotosPicker: Bool
    @Binding var images: [UIImage]
    @State private var currentPage: Int = 0

    let maxImages: Int

    // MARK: - UI

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(images.indices, id: \.self) { index in
                    imageView(index)
                }

                if images.count < maxImages {
                    addImageView
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            CustomPageControlIndicatorView(currentPage: $currentPage, numberOfPages: $images.count + (images.count < maxImages ? 1 : 0))
                .frame(height: 20)
                .padding()
        }
    }

    private func imageView(_ index: Int) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                Image(uiImage: images[index])
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width)
                    .clipped()
                    .cornerRadius(10)
                    .tag(index)

                Button {
                    deleteImage(at: index)
                } label: {
                    Image("trash")
                        .resizable()
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .padding(.leading, 20)
                        .padding(.bottom, 20)
                }
            }
            .scaleEffect(currentPage == index ? 1.0 : 0.9)
            .animation(.easeInOut, value: currentPage)
        }
    }

    private var addImageView: some View {
        VStack {
            Button {
                didShowPhotosPicker = true
            } label: {
                Image("addNewListing")
                    .resizable()
                    .frame(width: 64, height: 64)
            }
        }
        .shadow(radius: 5)
        .tag(images.count)
    }

    // MARK: - Functions

    private func deleteImage(at index: Int) {
        images.remove(at: index)
        if currentPage >= images.count {
            currentPage = images.count - 1
        }
    }
}
