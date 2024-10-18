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
                    .ignoresSafeArea()
            }
            .ignoresSafeArea()

            buttonGradientView

            if viewModel.didShowOptionsMenu {
                OptionsMenuView(showMenu: $viewModel.didShowOptionsMenu, options: [
                    // TODO: Replace with Deeplink
                    .share(url: URL(string: "https://www.google.com")!, itemName: item.title),
                    .report(destination: AnyView(Text("Placeholder"))),
                    .delete
                ])
                .zIndex(1)
            }
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
            VStack(alignment: .leading) {
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 50, height: 8)
                        .foregroundStyle(Constants.Colors.inactiveGray)
                        .padding(.top, 12)
                        .frame(alignment: .center)
                }
                .frame(maxWidth: .infinity, alignment: .center)


                titlePriceView

                sellerProfileView
                    .padding(.bottom, 24)

                itemDescriptionView
                    .padding(.bottom, 32)

                similarItemsView

                Spacer()
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
            .background(Color.white)
            .cornerRadius(40)
            .position(x: UIScreen.width / 2, y: max(150, UIScreen.main.bounds.width * viewModel.maxImgRatio - 50) + geometry.size.height / 2)
        }
    }

    private var titlePriceView: some View {
        HStack {
            Text(item.title)
                .font(Constants.Fonts.h2)
                .foregroundStyle(Constants.Colors.black)

            Spacer()

            Text("$\(item.price)")
                .font(Constants.Fonts.h2)
                .foregroundStyle(Constants.Colors.black)
        }
    }

    private var sellerProfileView: some View {
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
    }

    private var itemDescriptionView: some View {
        Text("Vintage blue pants that are super cool!\nCondition\nISBN\nAdditional Information")
            .font(Constants.Fonts.body2)
            .foregroundStyle(Constants.Colors.black)
    }

    private var similarItemsView: some View {
        VStack(alignment: .leading) {
            Text("Similar Items")
                .font(Constants.Fonts.title1)
                .foregroundStyle(Constants.Colors.black)

            HStack {
                let imageSize = (UIScreen.width - 72) / 4
                // TODO: Replace with similar items logic
                ForEach(0..<4, id: \.self) { _ in
                    Image("justin_long")
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(.rect(cornerRadius: 25))
                }
            }
        }
    }

    private var buttonGradientView: some View {
        VStack {
            PurpleButton(text: "Contact Seller") {
                // TODO: Chat with Seller
            }
        }
        .frame(width: UIScreen.width, height: 50)
        .background(
            LinearGradient(stops: [
                .init(color: Color.clear, location: 0.0),
                .init(color: Constants.Colors.white.opacity(0.8), location: 0.5),
                .init(color: Constants.Colors.white, location: 1.0)
            ], startPoint: .top, endPoint: .bottom)
        )
    }

}
