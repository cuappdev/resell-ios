//
//  ProductDetailsView.swift
//  Resell
//
//  Created by Richie Sun on 10/16/24.
//

import SwiftUI

struct ProductDetailsView: View {

    // MARK: - Properties

    @State private var currentPage: Int = 0
    @State private var images: [UIImage] = [UIImage(named: "justin")!, UIImage(named: "justin")!, UIImage(named: "justin_long")!, UIImage(named: "justin")!]
    @State private var maxImgRatio: CGFloat = 0.0

    var userIsSeller: Bool
    var item: Item
    var seller = ("Justin", "justin_long")

    // MARK: - UI

    var body: some View {
        VStack {
            imageGallery
                .frame(height: max(150, UIScreen.main.bounds.width * maxImgRatio))
                .onAppear {
                    calculateMaxImgRatio()
                }

            if maxImgRatio > 0 {
                detailsView
            }

        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                OptionsMenuView(options: [
                    Option(name: "Share", icon: "share") {

                    },
                    Option(name: "Report", icon: "flag") {

                    },
                    Option(name: "Delete", icon: "trash", isRed: true) {
                        
                    }
                ])
            }
        }
    }

    private var imageGallery: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                ForEach(images.indices, id: \.self) { index in
                    imageView(index)
                }
            }
            .background(Constants.Colors.white)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            CustomPageControlIndicatorView(currentPage: $currentPage, numberOfPages: $images.count)
                .frame(height: 20)
                .padding()
        }
        .ignoresSafeArea(edges: .top)
    }

    private func imageView(_ index: Int) -> some View {
        GeometryReader { geometry in
            Image(uiImage: images[index])
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width)
                .tag(index)
                .ignoresSafeArea(edges: .top)
        }
    }

    private var detailsView: some View {
        VStack {
            HStack {
                Text(item.title)
                    .font(Constants.Fonts.h2)
                    .foregroundStyle(Constants.Colors.black)

                Spacer()

                Text("$\(item.price)")
                    .font(Constants.Fonts.h2)
                    .foregroundStyle(Constants.Colors.black)
            }

            HStack() {
                Image(seller.1)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(.circle)

                Text(seller.0)
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.black)

                Spacer()
            }
        }
        .frame(maxHeight: 400)
        .background(Color.white)
        .padding(Constants.Spacing.horizontalPadding)
        .cornerRadius(20)
    }

    // MARK: - Functions

    private func calculateMaxImgRatio() {
        let maxAspectRatio = images.map { $0.aspectRatio }.max() ?? 1.0
        maxImgRatio = maxAspectRatio
    }
}


