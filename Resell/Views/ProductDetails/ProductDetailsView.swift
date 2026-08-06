//
//  ProductDetailsView.swift
//  Resell
//
//  Created by Richie Sun on 10/16/24.
//

import Kingfisher
import SwiftUI

struct ProductDetailsView: View {

    // MARK: - Properties

    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var router: Router

    @StateObject private var viewModel = ProductDetailsViewModel()
    @State private var isImageViewerPresented = false
    
    @ObservedObject private var homeViewModel = HomeViewModel.shared

    var post: Post

    /// Read the true top safe area inset from the window.
    private var topSafeArea: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }

    // Keep every listing's hero and sheet resting position consistent.
    private var imageHeight: CGFloat {
        UIScreen.main.bounds.height * 0.65
    }

    // MARK: - UI

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        ShimmerView()
                            .frame(height: imageHeight)
                    } else {
                        imageGallery
                            .frame(height: imageHeight)
                    }

                    Rectangle()
                        .fill(Constants.Colors.stroke)
                        .frame(height: 1)

                    detailsView
                        .background(Constants.Colors.white)
                }
            }

            if viewModel.didShowOptionsMenu {
                OptionsMenuView(showMenu: $viewModel.didShowOptionsMenu, didShowDeleteView: $viewModel.didShowDeleteView, options: {
                    var options: [Option] = []
                            
                    let urlString = "resell://product/\(post.id)"
                    if let shareUrl = URL(string: urlString) {
                        options.append(
                            .share(
                                url: shareUrl,
                                itemName: viewModel.item?.title ?? "Check out this AWESOME item on Resell!"
                            ))
                    }
                    
                    options.append(.report(type: "Post", id: post.id))
                    
                    if viewModel.isUserPost() {
                        options.append(.delete)
                    }
                    
                    return options
                }())
                .padding(.top, topSafeArea + 52)
                .zIndex(2)
            }
        }
        .background(Constants.Colors.white)
        // Pull content up to counteract NavigationStack's safe area inset
        .padding(.top, -topSafeArea)
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton(
                    style: .systemChevron
                )
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        viewModel.didShowOptionsMenu.toggle()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $viewModel.didShowDeleteView) {
                deletePostView
            }
            .onChange(of: viewModel.didShowDeleteView) { isPresented in
                if isPresented {
                    viewModel.didShowOptionsMenu = false
                }
            }
        .fullScreenCover(isPresented: $isImageViewerPresented) {
            ProductImageViewer(
                images: viewModel.images,
                selectedIndex: $viewModel.currentPage
            )
        }
        .onAppear {
            viewModel.setPost(post: post)
            viewModel.maxDrag = imageHeight
        }
        .onDisappear {
            viewModel.didShowOptionsMenu = false
        }
    }

    private var isSold: Bool {
        viewModel.item?.sold == true
    }

    @ViewBuilder
    private var imageGallery: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $viewModel.currentPage) {
                ForEach(viewModel.images.indices, id: \.self) { index in
                    imageView(index)
                }
            }
            .background(Constants.Colors.white)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            // Sold overlay
            if isSold {
                Rectangle()
                    .fill(Color.black.opacity(0.5))

                Text("Item Sold")
                    .font(.custom("Rubik-Medium", size: 24))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            CustomPageControlIndicatorView(currentPage: $viewModel.currentPage, numberOfPages: $viewModel.images.count)
                .frame(height: 20)
                .padding()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !viewModel.images.isEmpty else { return }
            isImageViewerPresented = true
        }
    }

    private func imageView(_ index: Int) -> some View {
        KFImage(viewModel.images[index])
            .cacheOriginalImage()
            .placeholder {
                ShimmerView()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .fade(duration: 0.3)
            .scaleFactor(UIScreen.main.scale)
            .backgroundDecode()
            .resizable()
            .scaledToFill()
            .frame(width: UIScreen.main.bounds.width, height: imageHeight)
            .tag(index)
            .clipped()
    }
    
    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 0) {
//            // Drag Handle
//            HStack {
//                RoundedRectangle(cornerRadius: 4)
//                    .frame(width: 50, height: 8)
//                    .foregroundStyle(Constants.Colors.inactiveGray)
//                    .padding(.top, 12)
//            }
//            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 12) {
                titlePriceView
                    .padding(.top, 12)

                sellerProfileView

                itemDescriptionView

                similarItemsView
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
            .padding(.bottom, 20)
        }
    }

    private var titlePriceView: some View {
        HStack {
            Text(viewModel.item?.title ?? "")
                .font(Constants.Fonts.h2)
                .foregroundStyle(Constants.Colors.black)

            Spacer()

            Text("$\(viewModel.item?.originalPrice ?? "0")")
                .font(Constants.Fonts.h2)
                .foregroundStyle(Constants.Colors.black)
        }
    }

    private var sellerProfileView: some View {
        HStack(spacing: 8) {
            Button {
                if viewModel.isMyPost() {
                    router.activeTab = 4
                    mainViewModel.selection = 4
                    router.popToRoot()
                } else {
                    router.push(.profile(viewModel.item?.user?.firebaseUid ?? ""))
                }
            } label: {
                HStack(spacing: 8) {
                    KFImage(viewModel.item?.user?.photoUrl)
                        .placeholder {
                            ShimmerView()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())

                    Text(viewModel.item?.user?.username ?? "")
                        .font(Constants.Fonts.body2)
                        .foregroundStyle(Constants.Colors.black)
                    
                    if !viewModel.isMyPost() {
                        Text("•")
                            .foregroundStyle(.black)
                            .font(Constants.Fonts.body2)
                        
                        Button {
                            contactSeller()
                        } label: {
                            Text("Contact Seller")
                                .font(Constants.Fonts.body2)
                                .foregroundStyle(Constants.Colors.resellPurple)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            saveButton
        }
    }

    private var itemDescriptionView: some View {
        Text(viewModel.item?.description ?? "")
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
                if viewModel.isLoadingImages {
                    ForEach(0..<4, id: \.self) { item in
                        ShimmerView()
                            .frame(width: imageSize, height: imageSize)
                            .clipShape(.rect(cornerRadius: 10))
                    }
                } else {
                    ForEach(viewModel.similarPosts, id: \.self.id) { item in
                        let url = URL(string: item.images.first ?? "")
                        if let url = url {
                            KFImage(url)
                                .placeholder {
                                    ShimmerView()
                                        .frame(width: imageSize, height: imageSize)
                                        .clipShape(.rect(cornerRadius: 10))
                                }
                                .resizable()
                                .scaledToFill()
                                .frame(width: imageSize, height: imageSize)
                                .clipShape(.rect(cornerRadius: 10))
                                .onTapGesture {
                                    changeItem(post: item)
                                }
                        }
                    }
                }
            }
        }
    }

    private func changeItem(post: Post) {
        viewModel.clear()
        viewModel.setPost(post: post)
        viewModel.maxDrag = imageHeight

        if let existingIndex = router.path.lastIndex(where: {
            if case .productDetails = $0 {
                return true
            }
            return false
        }) {
            router.path[existingIndex] = .productDetails(post)
        } else {
            router.push(.productDetails(post))
        }
    }

    private var saveButton: some View {
        Button {
            viewModel.isSaved.toggle()

            Task {
                await viewModel.updateItemSaved()
                await homeViewModel.toggleLocalSaveStatus(for: post, isSaving: viewModel.isSaved)
            }
        } label: {
            Image(viewModel.isSaved ? "saved.fill" : "saved")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 22)
                .foregroundStyle(viewModel.isSaved ? Constants.Colors.resellPurple : Constants.Colors.black)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var deletePostView: some View {
        VStack(spacing: 24) {
            Text("Delete Listing Permanently?")
                .font(Constants.Fonts.h3)
                .foregroundStyle(Constants.Colors.black)
                .multilineTextAlignment(.center)
                .padding(.top, 48)

            PurpleButton(isAlert: true, text: "Delete", horizontalPadding: 70) {
                viewModel.deletePost()
                viewModel.didShowOptionsMenu = false
                router.pop()
            }

            Button {
                viewModel.archivePost()
                viewModel.didShowOptionsMenu = false
                router.pop()
            } label: {
                Text("Archive Only")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.black)
            }
        }
        .background(Constants.Colors.white)
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(25)
        .presentationBackground(Constants.Colors.white)
    }

    // MARK: - Functions

    private func contactSeller() {
        guard let item = viewModel.item,
              let user = item.user,
              let me = GoogleAuthManager.shared.user else {
            return
        }

        let chatInfo = ChatInfo(
            listing: item,
            buyer: me,
            seller: user
        )
        navigateToChats(chatInfo: chatInfo)
    }

    private func navigateToChats(chatInfo: ChatInfo) {
        if let existingIndex = router.path.firstIndex(where: {
            if case .messages = $0 {
                return true
            }
            return false
        }) {
            router.path[existingIndex] = .messages(chatInfo: chatInfo)
            router.popTo(router.path[existingIndex])
        } else {
            router.push(.messages(chatInfo: chatInfo))
        }
    }
}

