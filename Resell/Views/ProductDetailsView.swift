//
//  ProductDetailsView.swift
//  Resell
//
//  Created by Richie Sun on 10/16/24.
//

import SwiftUI

struct ProductDetailsView: View {

    // MARK: - Properties

    @EnvironmentObject var mainViewModel: MainViewModel

    @StateObject private var viewModel = ProductDetailsViewModel()

    var userIsSeller: Bool
    var item: Item
    var seller = ("Justin", "justin_long")

    // MARK: - UI

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                imageGallery
                    .frame(height: max(150, UIScreen.main.bounds.width * viewModel.maxImgRatio))
                    .onAppear {
                        viewModel.calculateMaxImgRatio()
                    }

                if viewModel.maxImgRatio > 0 {
                    Spacer()
                }
            }
            .onChange(of: viewModel.maxImgRatio) { _ in
                print(max(150, UIScreen.main.bounds.width * viewModel.maxImgRatio))
            }
            
            DraggableSheetView(maxDrag: viewModel.maxDrag) {
                detailsView
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        viewModel.didShowOptionsMenu.toggle()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .resizable()
                        .frame(width: 24, height: 6)
                        .foregroundStyle(Constants.Colors.white)
                }
                .padding()
            }
        }
        .background {
            NavigationConfigurator { nc in
                nc.setLighterBackButton()
            }
        }
        .onAppear {
            withAnimation {
                mainViewModel.hidesTabBar = true
            }

            // TODO: move this when the image finishes downloading
            viewModel.maxDrag = max(150, UIScreen.main.bounds.width * viewModel.maxImgRatio)
        }
    }

    private var imageGallery: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $viewModel.currentPage) {
                ForEach(viewModel.images.indices, id: \.self) { index in
                    imageView(index)
                }
            }
            .background(Constants.Colors.white)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            CustomPageControlIndicatorView(currentPage: $viewModel.currentPage, numberOfPages: $viewModel.images.count)
                .frame(height: 20)
                .padding()
        }
        .ignoresSafeArea(edges: .top)
    }

    private func imageView(_ index: Int) -> some View {
        GeometryReader { geometry in
            Image(uiImage: viewModel.images[index])
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width)
                .tag(index)
                .ignoresSafeArea(edges: .top)
        }
    }

    private var detailsView: some View {
        GeometryReader { geometry in
            VStack {
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 50, height: 8)
                    .foregroundStyle(Constants.Colors.inactiveGray)
                    .padding(.top, 12)
                HStack {
                    Text(item.title)
                        .font(Constants.Fonts.h2)
                        .foregroundStyle(Constants.Colors.black)

                    Spacer()

                    Text("$\(item.price)")
                        .font(Constants.Fonts.h2)
                        .foregroundStyle(Constants.Colors.black)
                }

                HStack {
                    Image(seller.1)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())

                    Text(seller.0)
                        .font(Constants.Fonts.body2)
                        .foregroundStyle(Constants.Colors.black)

                    Spacer()
                }

                Spacer()
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
            .background(Color.white)
            .cornerRadius(40)
            .position(x: UIScreen.width / 2, y: max(150, UIScreen.main.bounds.width * viewModel.maxImgRatio - 50) + geometry.size.height / 2)
        }
    }

}
