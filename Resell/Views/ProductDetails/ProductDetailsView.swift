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
    /// True while the nav bar still overlays the hero image (vs white details).
    @State private var isToolbarOverHero: Bool = true
    /// True when the top-leading hero region is dark enough for light icons.
    /// Default black so light photos (sky, snow) aren't stuck with white icons
    /// before sampling finishes.
    @State private var heroPrefersLightIcons: Bool = false

    @ObservedObject private var homeViewModel = HomeViewModel.shared

    var post: Post

    private var toolbarIconTint: Color {
        if isToolbarOverHero {
            return heroPrefersLightIcons ? Constants.Colors.white : Constants.Colors.black
        }
        return Constants.Colors.black
    }

    private var toolbarIconShadow: Color {
        guard isToolbarOverHero else { return .clear }
        return heroPrefersLightIcons
            ? Color.black.opacity(0.45)
            : Color.white.opacity(0.7)
    }

    /// Read the true top safe area inset from the window.
    private var topSafeArea: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }

    // Keep every listing's hero height consistent.
    private var imageHeight: CGFloat {
        UIScreen.main.bounds.height * 0.65
    }

    /// How far the rounded details card overlaps the hero.
    private let detailsOverlap: CGFloat = 28
    private let detailsCornerRadius: CGFloat = 24

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

                    detailsView
                        .padding(.top, 8)
                        .background(Constants.Colors.white)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: detailsCornerRadius,
                                topTrailingRadius: detailsCornerRadius,
                                style: .continuous
                            )
                        )
                        .padding(.top, -detailsOverlap)
                        .zIndex(1)
                }
            }
            // Destination pages don't inherit the tab-root bottom inset, so
            // Similar Items would otherwise sit under the floating tab bar.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: 110)
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
        .enableSwipeBack()
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton(
                    style: .systemChevron,
                    tint: toolbarIconTint
                )
                .shadow(color: toolbarIconShadow, radius: 2, y: 1)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        viewModel.didShowOptionsMenu.toggle()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(toolbarIconTint)
                        .shadow(color: toolbarIconShadow, radius: 2, y: 1)
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
            updateHeroIconContrast()
        }
        .onChange(of: viewModel.currentPage) { _ in
            updateHeroIconContrast()
        }
        .onChange(of: viewModel.images) { _ in
            updateHeroIconContrast()
        }
        .onChange(of: viewModel.item?.sold) { _ in
            updateHeroIconContrast()
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
        ZStack(alignment: .bottomTrailing) {
            imagePager

            if isSold {
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .allowsHitTesting(false)

                Text("Item Sold")
                    .font(.custom("Rubik-Medium", size: 24))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            }

            if viewModel.images.count > 0 {
                imageCountBadge
                    .padding(.trailing, 16)
                    .padding(.bottom, detailsOverlap + 14)
            }
        }
        .clipped()
        // When the hero scrolls out from under the toolbar, flip icons to black.
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.frame(in: .global).maxY
        } action: { maxY in
            let toolbarBottom = topSafeArea + 52
            let overHero = maxY > toolbarBottom
            guard overHero != isToolbarOverHero else { return }
            withAnimation(.easeInOut(duration: 0.15)) {
                isToolbarOverHero = overHero
            }
        }
    }

    /// Horizontal paging carousel — swipe between photos on the listing itself.
    private var imagePager: some View {
        TabView(selection: $viewModel.currentPage) {
            ForEach(viewModel.images.indices, id: \.self) { index in
                imageView(index)
                    .onTapGesture {
                        isImageViewerPresented = true
                    }
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .background(Constants.Colors.white)
    }

    private var imageCountBadge: some View {
        Text("\(viewModel.currentPage + 1) / \(viewModel.images.count)")
            .font(Constants.Fonts.title3)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(0.55), in: Capsule())
            .accessibilityLabel("Image \(viewModel.currentPage + 1) of \(viewModel.images.count)")
    }

    /// Sample the top-leading corner of the current hero image for icon contrast.
    private func updateHeroIconContrast() {
        // Sold dimming always reads as a dark surface.
        if isSold {
            heroPrefersLightIcons = true
            return
        }

        guard viewModel.images.indices.contains(viewModel.currentPage) else {
            heroPrefersLightIcons = false
            return
        }

        let url = viewModel.images[viewModel.currentPage]
        let sampleSize = CGSize(width: UIScreen.main.bounds.width, height: imageHeight)
        KingfisherManager.shared.retrieveImage(with: url) { result in
            let prefersLight: Bool
            if case .success(let value) = result {
                prefersLight = value.image.prefersLightToolbarIcons(displayedIn: sampleSize)
            } else {
                prefersLight = false
            }

            Task { @MainActor in
                guard viewModel.images.indices.contains(viewModel.currentPage),
                      url == viewModel.images[viewModel.currentPage] else { return }
                withAnimation(.easeInOut(duration: 0.15)) {
                    heroPrefersLightIcons = prefersLight
                }
            }
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
        VStack(alignment: .leading, spacing: 12) {
            titlePriceView
                .padding(.top, 20)

            sellerProfileView

            itemDescriptionView

            similarItemsView
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .padding(.bottom, 28)
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
                    router.activeTab = Router.Tab.profile.rawValue
                    mainViewModel.selection = Router.Tab.profile.rawValue
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

