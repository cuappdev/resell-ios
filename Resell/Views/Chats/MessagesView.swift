//
//  MessagesView.swift
//  Resell
//
//  Created by Richie Sun on 10/26/24.
//

import Kingfisher
import PhotosUI
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
                messageListView

                Spacer()

                Divider()

                messageInputView
            }

            if didShowOptionsMenu {
                OptionsMenuView(showMenu: $didShowOptionsMenu, options: [.report(type: "User", id: viewModel.otherUser?.id ?? "")])
                    .padding(.top, (UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0) + 30)
                    .zIndex(1)
            }
        }
        .background(Constants.Colors.white)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button {
                    navigateToProductDetails(post: post)
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
        .sheet(isPresented: $didShowNegotiationView, onDismiss: setNegotiationText) {
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
        .sheet(isPresented: $didShowAvailabilityView) {
            AvailabilitySelectorView(isPresented: $didShowAvailabilityView)
                .presentationCornerRadius(25)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $didShowWebView) {
            WebView(url: viewModel.venmoURL!)
                .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            guard let myEmail = UserSessionManager.shared.email,
                  let myID = UserSessionManager.shared.userID else {
                UserSessionManager.shared.logger.error("Error in MessagesView: User Email Not Found")
                return
            }
            viewModel.parsePayWithVenmoURL(email: viewModel.selectedChat?.email ?? "")

            viewModel.subscribeToChat(
                myEmail: myEmail,
                otherEmail: viewModel.selectedChat?.email ?? "",
                selfIsBuyer: !(post.user?.id == myID)
            )
            
            viewModel.getOtherUser(email: viewModel.selectedChat?.email ?? "")
        }
        .endEditingOnTap()

    }

    private var messageListView: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                VStack {
                    ForEach(viewModel.subscribedChat?.history ?? []) { cluster in
                        VStack(spacing: 10) {
                            ForEach(cluster.messages) { message in
                                MessageBubbleView(message: message, fromUser: cluster.fromUser)
                            }
                        }
                    }
                }
                .onChange(of: viewModel.subscribedChat?.history.count) { _ in
                    if let lastMessage = viewModel.subscribedChat?.history.last?.messages.last?.id {
                        scrollViewProxy.scrollTo(lastMessage, anchor: .bottom)
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
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
        TextInputView(draftMessageText: $viewModel.draftMessageText) { text, image in
            print("Text: \(text ?? "No text")")
            onSend()
            if let image = image {
                print("Image selected")
            }
        }
    }

    // MARK: - Functions

    private func navigateToProductDetails(post: Post) {
        if let existingIndex = router.path.firstIndex(where: {
            if case .productDetails = $0 {
                return true
            }
            return false
        }) {
            router.path[existingIndex] = .productDetails(post)
            router.popTo(router.path[existingIndex])
        } else {
            router.push(.productDetails(post))
        }
    }

    private func onSend() {
        // TODO: Implement Send
    }

    private func setNegotiationText() {
        viewModel.draftMessageText = "Hi! I'm interested in buying your \(post.title), but would you be open to selling it for $\(priceText)?"
        priceText = ""
    }
}

// MARK: - MessageBubbleView

struct MessageBubbleView: View {
    let message: ChatMessageData
    let fromUser: Bool

    var body: some View {
        HStack {
            if !fromUser {
                profileImageView
            }

            VStack(alignment: fromUser ? .trailing : .leading) {
                messageContentView
                Text(message.timestampString)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            if fromUser {
                Spacer()
            }
        }
        .padding(fromUser ? .leading : .trailing, 60)
    }

    @ViewBuilder
    private var messageContentView: some View {
        switch message.messageType {
        case .image:
            if let url = URL(string: message.imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } placeholder: {
                    ProgressView()
                }
            }
        case .message:
            Text(message.content)
                .padding()
                .background(fromUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(fromUser ? .white : .black)
                .cornerRadius(10)
        case .availability:
            Text("Availability: \(message.content)")
                .padding()
                .background(Color.green.opacity(0.2))
                .cornerRadius(10)
        default:
            Text("Unsupported message type.")
        }
    }

    private var profileImageView: some View {
        Circle()
            .fill(Color.gray)
            .frame(width: 40, height: 40)
    }
}



// MARK: - TextInputView

struct TextInputView: View {

    // MARK: - Properties

    @State private var selectedImage: UIImage? = nil
    @State private var showingPhotoPicker = false
    @Binding var draftMessageText: String

    let onSend: (String?, UIImage?) -> Void
    let maxCharacters: Int = 1000

    // MARK: - UI

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                // Image Preview with Delete Option
                if let selectedImage = selectedImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Button(action: {
                            self.selectedImage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                                .padding(4)
                        }
                    }
                    .padding(.leading, 32)
                }

                HStack {
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Constants.Colors.secondaryGray)
                    }
                    .sheet(isPresented: $showingPhotoPicker) {
                        SingleImagePicker(selectedImage: $selectedImage)
                    }

                    TextEditor(text: $draftMessageText)
                        .font(Constants.Fonts.body2)
                        .foregroundColor(Constants.Colors.black)
                        .padding(12)
                        .scrollContentBackground(.hidden)
                        .background(Constants.Colors.wash)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .frame(height: 48)
                        .onChange(of: draftMessageText) { newText in
                            if newText.count > maxCharacters {
                                draftMessageText = String(newText.prefix(maxCharacters))
                            }
                        }
                }

            }

            if !draftMessageText.isEmpty || selectedImage != nil {
                Button(action: {
                    onSend(draftMessageText.isEmpty ? nil : draftMessageText, selectedImage)
                    draftMessageText = ""
                    selectedImage = nil
                }) {
                    Image("sendButton")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .padding(.trailing, 8)
            }
        }
        .padding(.trailing, 24)
        .padding(.leading, 8)
    }
}

// MARK: - ImagePicker View

struct SingleImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: SingleImagePicker

        init(_ parent: SingleImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
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
