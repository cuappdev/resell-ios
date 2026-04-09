//
//  ProductDetailsView.swift
//  Resell
//
//  Created by Richie Sun on 10/16/24.
//

import Kingfisher
import SwiftUI
import UserNotifications

struct ProductDetailsView: View {

    // MARK: - Properties

    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var router: Router

    @StateObject private var viewModel = ProductDetailsViewModel()

    var post: Post

    /// Read the true top safe area inset from the window.
    private var topSafeArea: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 0
    }

    // Base image height before adding safe area compensation
    private var baseImageHeight: CGFloat {
        UIScreen.main.bounds.width * 1.5
    }

    // Total image height including safe area so the image extends behind the status bar
    private var imageHeight: CGFloat {
        baseImageHeight + topSafeArea
    }

    // MARK: - UI

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ShimmerView()
                        .frame(height: imageHeight)
                } else {
                    imageGallery
                        .frame(height: imageHeight)
                }

                Spacer()
            }

            DraggableSheetView(startY: imageHeight) {
                detailsView
            }

            if !viewModel.isMyPost() {
                buttonGradientView
            }

            if viewModel.didShowOptionsMenu {
                OptionsMenuView(showMenu: $viewModel.didShowOptionsMenu, didShowDeleteView: $viewModel.didShowDeleteView, options: {
                    var options: [Option] = [
                        .report(type: "Post", id: post.id)
                    ]
                    if viewModel.isUserPost() {
                        options.append(.delete)
                    }
                    return options
                }())
                .padding(.top, topSafeArea * 2 + 30)
                .zIndex(2)
            }

            // Custom navigation buttons overlay
            VStack {
                HStack {
                    Button {
                        router.pop()
                    } label: {
                        Image("chevron.left.white")
                            .resizable()
                            .frame(width: 36, height: 24)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .padding(.leading, 12)

                    Spacer()

                    Button {
                        withAnimation {
                            viewModel.didShowOptionsMenu.toggle()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .resizable()
                            .frame(width: 24, height: 6)
                            .foregroundStyle(Constants.Colors.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .padding(.trailing, 12)
                }
                .padding(.top, topSafeArea * 2 + 4)

                Spacer()
            }
            .zIndex(1)
        }
        .background(Constants.Colors.white)
        // Pull content up to counteract NavigationStack's safe area inset
        .padding(.top, -topSafeArea)
        .ignoresSafeArea(edges: .top)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $viewModel.didShowDeleteView) {
                deletePostView
            }
            .onChange(of: viewModel.didShowDeleteView) { isPresented in
                if isPresented {
                    viewModel.didShowOptionsMenu = false
                }
            }
        .onAppear {
            viewModel.setPost(post: post)

            withAnimation {
                mainViewModel.hidesTabBar = true
            }

            viewModel.maxDrag = imageHeight
        }
        .onDisappear {
            viewModel.didShowOptionsMenu = false
            withAnimation {
                mainViewModel.hidesTabBar = false
            }
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
    }

    private func imageView(_ index: Int) -> some View {
        KFImage(viewModel.images[index])
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

//    private var detailsView: some View {
//        
//        GeometryReader { geometry in
//            VStack(alignment: .leading) {
//                HStack {
//                    RoundedRectangle(cornerRadius: 4)
//                        .frame(width: 50, height: 8)
//                        .foregroundStyle(Constants.Colors.inactiveGray)
//                        .padding(.top, 12)
//                        .frame(alignment: .center)
//                }
//                .frame(maxWidth: .infinity, alignment: .center)
//
//                titlePriceView
//
//                sellerProfileView
//                    .padding(.bottom, 24)
//
//                itemDescriptionView
//                    .padding(.bottom, 32)
//
//                similarItemsView
//
//                Spacer()
//            }
//            .padding(.horizontal, Constants.Spacing.horizontalPadding)
//            .background(Color.white)
//            .cornerRadius(40)
//            .position(x: UIScreen.width / 2, y: imageHeight - 50 + geometry.size.height / 2)
//        }
//    }
    
    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Drag Handle
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 50, height: 8)
                    .foregroundStyle(Constants.Colors.inactiveGray)
                    .padding(.top, 12)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading) {
                titlePriceView
                    .padding(.top, 10)
                
                sellerProfileView
                    .padding(.bottom, 24)

                itemDescriptionView
                    .padding(.bottom, 32)

                similarItemsView
                
                // This ensures the sheet is tall enough to cover the screen when pulled up
                Spacer(minLength: 500)
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
        }
        .background(Color.white)
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
        Button {
            if viewModel.isMyPost() {
                mainViewModel.selection = 2
                router.popToRoot()
            } else {
                router.push(.profile(viewModel.item?.user?.firebaseUid ?? ""))
            }
        } label: {
            HStack {
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

                Spacer()
            }
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

        withAnimation {
            mainViewModel.hidesTabBar = true
        }

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

    private var buttonGradientView: some View {
        VStack {
            PurpleButton(text: "Contact Seller") {
                if let item = viewModel.item, let user = item.user, let me = GoogleAuthManager.shared.user {
                    let chatInfo = ChatInfo(
                        listing: item,
                        buyer: me,
                        seller: user
                    )

                    navigateToChats(chatInfo: chatInfo)
                }
            }
        }
        .frame(width: UIScreen.width, height: 50)
        .padding(.bottom, 24)
        .background(
            LinearGradient(stops: [
                .init(color: Color.clear, location: 0.0),
                .init(color: Constants.Colors.white.opacity(0.8), location: 0.5),
                .init(color: Constants.Colors.white, location: 1.0)
            ], startPoint: .top, endPoint: .bottom)
        )
    }

    // TODO: FIX

    func sendNotification() {
        let content = UNMutableNotificationContent()
        content.title = "New Post"
        content.subtitle = "Testing bookmarks"
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            } else {
                print("Push notification sent successfully!")
            }
        }
    }

    func requestNotificationAuthorization() {
        @AppStorage("isNotificationAuthorized") var isNotificationAuthorized = false
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
                return
            }

            if granted {
                isNotificationAuthorized = true
                print("Notification permission granted.")
            } else {
                isNotificationAuthorized = false
                print("Notification permission denied.")
            }
        }
    }

    @AppStorage("isNotificationAuthorized") var isNotificationAuthorized = false

//    private var saveButton: some View {
//        if isNotificationAuthorized {
//            Button {
//                viewModel.isSaved.toggle()
//                viewModel.updateItemSaved()
//                sendNotification()
//            } label: {
//                ZStack {
//                    Circle()
//                        .frame(width: 72, height: 72)
//                        .foregroundStyle(Constants.Colors.white)
//                        .opacity(viewModel.isSaved ? 1.0 : 0.9)
//                        .shadow(radius: 2)
//
//                    Image(viewModel.isSaved ? "saved.fill" : "saved")
//                        .resizable()
//                        .frame(width: 21, height: 27)
//                }
//            }
//        } else {
//            Button {
//                viewModel.isSaved.toggle()
//                viewModel.updateItemSaved()
//                requestNotificationAuthorization()
//                print("Test1")
//            } label: {
//                ZStack {
//                    Circle()
//                        .frame(width: 72, height: 72)
//                        .foregroundStyle(Constants.Colors.white)
//                        .opacity(viewModel.isSaved ? 1.0 : 0.9)
//                        .shadow(radius: 2)
//
//                    Image(viewModel.isSaved ? "saved.fill" : "saved")
//                        .resizable()
//                        .frame(width: 21, height: 27)
//                }
//            }
//        }
//    }

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

