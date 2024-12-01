//
//  MessagesView.swift
//  Resell
//
//  Created by Richie Sun on 10/26/24.
//

import Kingfisher
import SwiftUI

// MARK: - MessageView
struct MessagesView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: ChatsViewModel

    @State private var didShowOptionsMenu: Bool = false
    @State private var didShowNegotiationView: Bool = false
    @State private var didShowAvailabilityView: Bool = false
    @State private var didShowWebView: Bool = false

    @State private var priceText: String = ""

    var post: Post
    let maxCharacters: Int = 1000

    // MARK: - UI

    var body: some View {
        ZStack {
            VStack {
                //            messageContentView

                Spacer()

                Divider()

                messageInputView

            }

            if didShowOptionsMenu {
                OptionsMenuView(showMenu: $didShowOptionsMenu, options: [.report(type: "User", id: post.user?.id ?? "")])
                .padding(.top, (UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0) + 30)
                .zIndex(1)
            }
        }
        .background(Constants.Colors.white)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button {
                    navigateToProductDetails(postID: post.id)
                } label: {
                    VStack(spacing: 0) {
                        Text(post.title)
                            .font(Constants.Fonts.title1)
                            .foregroundStyle(Constants.Colors.black)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Text("\(post.user?.givenName ?? "") \(post.user?.familyName ?? "")")
                            .font(Constants.Fonts.title3)
                            .foregroundStyle(Constants.Colors.secondaryGray)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        didShowOptionsMenu.toggle()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .resizable()
                        .frame(width: 24, height: 6)
                        .foregroundStyle(Constants.Colors.black)
                }
                .padding()
            }
        }
        .sheet(isPresented: $didShowNegotiationView) {
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    KFImage(post.images.first)
                        .placeholder {
                            ShimmerView()
                                .frame(width: 128, height: 100)
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 128, height: 100)
                        .clipShape(.rect(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 8) {
                        Text(post.title)
                            .font(Constants.Fonts.h2)
                            .foregroundStyle(Constants.Colors.black)

                        Text("$\(post.alteredPrice)")
                            .font(Constants.Fonts.body1)
                            .foregroundStyle(Constants.Colors.black)
                    }

                    Spacer()
                }
                .padding(16)
                .frame(width: UIScreen.width - 40, height: 125)
                .background(Constants.Colors.white)
                .clipShape(.rect(cornerRadius: 18))

                PriceInputView(price: $priceText, isPresented: $didShowNegotiationView, titleText: "What price do you want to propose?")
                    .padding(.bottom, 24)
                    .background(Constants.Colors.white)
                    .clipShape(.rect(cornerRadii: .init(topLeading: 25, topTrailing: 25)))
                    .overlay(alignment: .top) {
                        Rectangle()
                            .foregroundStyle(Constants.Colors.stroke)
                            .frame(width: 66, height: 6)
                            .clipShape(.capsule)
                            .padding(.top, 12)
                    }
            }
            .presentationDetents([.height(UIScreen.height * 3/4)])
            .presentationBackground(.clear)
            .ignoresSafeArea()
        }
        .onChange(of: didShowNegotiationView) { newValue in
            if !newValue && !priceText.isEmpty {
                viewModel.draftMessageText = "Hi! I'm interested in buying your \(post.title), but would you be open to selling it for $\(priceText)?"
                priceText = ""
            }
        }

    }

    private var messageInputView: some View {
        VStack(spacing: 12) {
            filtersView

            textInputView
        }
    }

    private var filtersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Constants.chatMessageOptions, id: \.self) { option in
                    switch option {
                    case .negotiate:
                        chatOption(title: option.rawValue) {
                            withAnimation { didShowNegotiationView = true }
                        }
                    case .sendAvailability:
                        chatOption(title: option.rawValue) {
                            withAnimation { didShowAvailabilityView = true }
                        }
                    case .venmo:
                        chatOption(title: option.rawValue) {
                            withAnimation { didShowWebView = true }
                        }
                    case .viewAvailability:
                        chatOption(title: "View \(post.user?.givenName ?? "")'s Availability") {
                            withAnimation { didShowAvailabilityView = true }
                        }
                    }
                }
            }
            .padding(.vertical, 1)
            .padding(.leading, 8)
        }
    }

    private func chatOption(title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(Constants.Fonts.title3)
                .foregroundStyle(Constants.Colors.black)
                .lineLimit(1)
        }
        .padding(12)
        .overlay {
            RoundedRectangle(cornerRadius: 25)
                .stroke(Constants.Colors.resellGradient, lineWidth: 2)
        }
    }

    private var textInputView: some View {
        HStack(spacing: 8) {
            Button {

            } label: {
                Image(systemName: "photo")
                    .foregroundStyle(Constants.Colors.secondaryGray)
            }

            TextEditor(text: $viewModel.draftMessageText)
                .font(Constants.Fonts.body2)
                .foregroundColor(Constants.Colors.black)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(Constants.Colors.wash)
                .clipShape(.rect(cornerRadius: 10))
                .frame(height: 48)
                .onChange(of: viewModel.draftMessageText) { newText in
                    if newText.count > maxCharacters {
                        viewModel.draftMessageText = String(newText.prefix(maxCharacters))
                    }
                }
                .overlay(alignment: .trailing) {
                    if !viewModel.draftMessageText.isEmpty {
                        Button(action: onSend) {
                            Image("sendButton")
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        .padding(.trailing, 8)
                    }
                }
        }
        .padding(.trailing, 24)
        .padding(.leading, 8)
    }

    // MARK: - Functions

    private func navigateToProductDetails(postID: String) {
        if let existingIndex = router.path.firstIndex(where: {
            if case .productDetails = $0 {
                return true
            }
            return false
        }) {
            router.path[existingIndex] = .productDetails(postID)
            router.popTo(router.path[existingIndex])
        } else {
            router.push(.productDetails(postID))
        }
    }

    private func onSend() {

    }

//    private var messageContentView: some View {
//        ScrollViewReader { scrollViewProxy in
//            ScrollView {
//                VStack {
//                    ForEach(viewModel.messages) { message in
//                        MessageBubbleView(message: message)
//                    }
//                }
//                .onChange(of: viewModel.messages.count) { _ in
//                    if let lastMessage = viewModel.messages.last?.id {
//                        scrollViewProxy.scrollTo(lastMessage, anchor: .bottom)
//                    }
//                }
//            }
//            .background(Constants.Colors.white)
//            .onAppear {
//                viewModel.fetchMessages()
//            }
//        }
//    }
}

// MARK: - MessageBubbleView
//struct MessageBubbleView: View {
//    let message: Message
//
//    var body: some View {
//        HStack(alignment: .bottom, spacing: 10) {
//            if message.isSentByCurrentUser {
//                Spacer()
//            }
//
//            if !message.isSentByCurrentUser {
//                AsyncImage(url: URL(string: message.user.avatar)) { image in
//                    image.resizable()
//                } placeholder: {
//                    Circle().fill(Color.gray)
//                }
//                .frame(width: 40, height: 40)
//                .clipShape(Circle())
//            }
//
//            VStack(alignment: message.isSentByCurrentUser ? .trailing : .leading) {
//                Text(message.text)
//                    .padding()
//                    .background(message.isSentByCurrentUser ? Color.blue : Color.gray.opacity(0.2))
//                    .foregroundColor(message.isSentByCurrentUser ? .white : .black)
//                    .cornerRadius(15)
//
//                Text(message.createdAt, style: .time)
//                    .font(.caption2)
//                    .foregroundColor(.gray)
//            }
//
//            if !message.isSentByCurrentUser {
//                Spacer()
//            }
//        }
//        .padding(message.isSentByCurrentUser ? .leading : .trailing, 60)
//        .padding(.vertical, 5)
//    }
//}
