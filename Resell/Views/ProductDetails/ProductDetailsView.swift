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

    // MARK: - UI

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                if viewModel.isLoading {
                    ShimmerView()
                        .frame(height: max(150, UIScreen.main.bounds.width * viewModel.maxImgRatio))
                        .ignoresSafeArea()
                } else {
                    imageGallery
                        .frame(height: max(150, UIScreen.main.bounds.width * viewModel.maxImgRatio))
                }

                if viewModel.maxImgRatio > 0 {
                    Spacer()
                }
            }

            DraggableSheetView(maxDrag: viewModel.maxDrag) {
                detailsView
            }
            .ignoresSafeArea()

            if !viewModel.isMyPost() {
                buttonGradientView
            }

            if viewModel.didShowOptionsMenu {
                OptionsMenuView(showMenu: $viewModel.didShowOptionsMenu, didShowDeleteView: $viewModel.didShowDeleteView, options: {
                    var options: [Option] = [
                        .share(url: URL(string: "https://www.google.com")!, itemName: viewModel.item?.title ?? ""),
                        .report(type: "Post", id: post.id)
                    ]
                    if viewModel.isUserPost() {
                        options.append(.delete)
                    }
                    return options
                }())
                .padding(.top, (UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0) + 30)
                .zIndex(1)
            }
        }
        .background(Constants.Colors.white)
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    router.pop()
                } label: {
                    Image("chevron.left.white")
                        .resizable()
                        .frame(width: 36, height: 24)
                }
            }

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
        .sheet(isPresented: $viewModel.didShowDeleteView) {
            deletePostView
                .background(Constants.Colors.white)
        }
        .onAppear {
            viewModel.setPost(post: post)

            withAnimation {
                mainViewModel.hidesTabBar = true
            }

            // Set the max drag when the image finishes downloading
            viewModel.maxDrag = max(150, UIScreen.main.bounds.width * viewModel.maxImgRatio)
        }
        .onDisappear {
            viewModel.didShowOptionsMenu = false
            withAnimation {
                mainViewModel.hidesTabBar = false
            }
        }
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

            CustomPageControlIndicatorView(currentPage: $viewModel.currentPage, numberOfPages: $viewModel.images.count)
                .frame(height: 20)
                .padding()
        }
        .ignoresSafeArea(edges: .top)
    }

    private func imageView(_ index: Int) -> some View {
        GeometryReader { geometry in
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
                .frame(width: geometry.size.width)
                .tag(index)
                .aspectRatio(contentMode: .fill)
                .clipped()
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
            .overlay(alignment: .trailing) {
                saveButton
                    .position(x: UIScreen.width - 60, y: max(150, UIScreen.main.bounds.width * viewModel.maxImgRatio - 110))
            }
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
        Button {
            router.push(.profile(viewModel.item?.user?.firebaseUid ?? ""))
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

        viewModel.maxDrag = max(150, UIScreen.main.bounds.width * viewModel.maxImgRatio)

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
    
    private var saveButton: some View {
        if isNotificationAuthorized {
            Button {
                viewModel.isSaved.toggle()
                viewModel.updateItemSaved()
                sendNotification()
                //viewModel.createNewNotif()
            } label: {
                ZStack {
                    Circle()
                        .frame(width: 72, height: 72)
                        .foregroundStyle(Constants.Colors.white)
                        .opacity(viewModel.isSaved ? 1.0 : 0.9)
                        .shadow(radius: 2)

                    Image(viewModel.isSaved ? "saved.fill" : "saved")
                        .resizable()
                        .frame(width: 21, height: 27)
                }
            }
        } else {
            Button {
                viewModel.isSaved.toggle()
                viewModel.updateItemSaved()
                requestNotificationAuthorization()
                print("Test1")
            } label: {
                ZStack {
                    Circle()
                        .frame(width: 72, height: 72)
                        .foregroundStyle(Constants.Colors.white)
                        .opacity(viewModel.isSaved ? 1.0 : 0.9)
                        .shadow(radius: 2)

                    Image(viewModel.isSaved ? "saved.fill" : "saved")
                        .resizable()
                        .frame(width: 21, height: 27)
                }
            }
        }
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
