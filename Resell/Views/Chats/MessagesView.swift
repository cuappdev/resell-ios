//
//  MessagesView.swift
//  Resell
//
//  Created by Richie Sun on 10/26/24.
//

import Kingfisher
import PhotosUI
import SwiftUI

struct MessagesView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    @State private var didShowOptionsMenu: Bool = false
    @State private var didShowNegotiationView: Bool = false
    @State private var didShowAvailabilityView: Bool = false
    @State private var didShowWebView: Bool = false
    @State private var didSubmitAvailabilities: Bool = false
    @State private var isEditing: Bool = true
    @State private var priceText: String = ""
    @StateObject private var viewModel: ViewModel

    // MARK: - Init

    init(chatInfo: SimpleChatInfo) {
        _viewModel = StateObject(wrappedValue: ViewModel(simpleChatInfo: chatInfo))
    }

    // MARK: - UI

    var body: some View {
        ZStack {
            mainContentView

            if didShowOptionsMenu {
                optionsMenuOverlay
            }
        }
        .background(Constants.Colors.white)
        .toolbarBackground(Constants.Colors.white, for: .automatic)
        .toolbar {
            ToolbarItem(placement: .principal) {
                headerButton
            }

            ToolbarItem(placement: .topBarTrailing) {
                optionsButton
            }
        }
        .sheet(isPresented: $didShowNegotiationView, onDismiss: setNegotiationText) {
            negotiationView
        }
        .sheet(isPresented: $didShowAvailabilityView) {
            availabilityView
        }
        .sheet(isPresented: $didShowWebView) {
            webView
        }
        .onAppear(perform: setupOnAppear)
        .onDisappear {
            FirestoreManager.shared.stopListening()
        }
        .onChange(of: didSubmitAvailabilities, perform: handleAvailabilitySubmit)
        .endEditingOnTap()
    }

    // MARK: - Extracted Subviews

    private var mainContentView: some View {
        VStack {
            messageListView
            Spacer()
            Divider()
            messageInputView
        }
    }

    private var optionsMenuOverlay: some View {
        OptionsMenuView(showMenu: $didShowOptionsMenu, options: [.report(type: "User", id: viewModel.chatInfo?.buyer.firebaseUid ?? "")])
            .zIndex(100)
    }
    
    private var headerButton: some View {
        Button {
            navigateToProductDetails()
        } label: {
            VStack(spacing: 0) {
                Text(viewModel.chatInfo?.listing.title ?? "Listing")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.black)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("\(viewModel.chatInfo?.listing.user?.givenName ?? "") \(viewModel.chatInfo?.listing.user?.familyName ?? "")")
                    .font(Constants.Fonts.title3)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }
    
    private var optionsButton: some View {
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
    
    private var messageListView: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.messageClusters) { cluster in
                            messageCluster(cluster: cluster)
                        }
                        Color.clear.frame(height: 1).id("BOTTOM")
                    }
                }
                .padding(.horizontal, 12)
                .background(Constants.Colors.white)
                .onChange(of: viewModel.messageClusters) { _ in
                    withAnimation {
                        proxy.scrollTo("BOTTOM", anchor: .bottom)
                    }
                }
                .onAppear {
                    withAnimation {
                        proxy.scrollTo("BOTTOM", anchor: .bottom)
                    }
                }
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
        FilterOptionsView(
            didShowNegotiationView: $didShowNegotiationView,
            didShowAvailabilityView: $didShowAvailabilityView, 
            didShowWebView: $didShowWebView,
            isEditing: $isEditing,
            viewModel: viewModel
        )
    }

    private func messageCluster(cluster: MessageCluster) -> some View {
        VStack(spacing: 12) {
            ForEach(cluster.messages, id: \.messageId) { message in
                MessageBubbleView(
                    didShowAvailabilityView: $didShowAvailabilityView, 
                    isEditing: $isEditing, 
                    selectedAvailabilities: $viewModel.availability, 
                    message: message, 
                    messageLocation: cluster.location
                )
            }
        }
    }

    private var textInputView: some View {
        TextInputView(draftMessageText: $viewModel.draftMessageText) { text, images in
            let b46Images = images?.compactMap { $0.toBase64() } ?? []
            Task {
                try await viewModel.sendMessage(text: text, imagesBase64: b46Images)
            }
        }
    }

    private var negotiationView: some View {
        NegotiationSheetView(
            chatInfo: viewModel.chatInfo,
            priceText: $priceText,
            isPresented: $didShowNegotiationView
        )
    }
    
    private var availabilityView: some View {
        AvailabilitySelectorView(
            isPresented: $didShowAvailabilityView,
            selectedDates: $viewModel.availability,
            didSubmit: $didSubmitAvailabilities
        )
        .presentationCornerRadius(25)
        .presentationDragIndicator(.hidden)
    }

    private var webView: some View {
        Group {
            if let url = viewModel.venmoURL {
                WebView(url: url)
                    .edgesIgnoringSafeArea(.all)
            } else {
                EmptyView()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupOnAppear() {
        guard GoogleAuthManager.shared.user != nil else {
            GoogleAuthManager.shared.logger.error("Error in \(#file) \(#function): User not available.")
            return
        }

        viewModel.parsePayWithVenmoURL()
        viewModel.subscribeToChat()
    }
    
    private func handleAvailabilitySubmit(_ didSubmit: Bool) {
        if didSubmit {
            Task {
                // TODO: fix
                // await sendAvailabilities(availabilities: viewModel.availabilityDates)
                viewModel.availability = []
                didSubmitAvailabilities = false
            }
        }
    }

    private func navigateToProductDetails() {
        guard let post = viewModel.chatInfo?.listing else { return }

        if let existingIndex = router.path.firstIndex(where: {
            if case let .productDetails(existingPost) = $0, existingPost.id == post.id {
                return true
            }
            return false
        }) {
            router.popTo(router.path[existingIndex])
        } else {
            router.push(.productDetails(post))
        }
    }

    private func setNegotiationText() {
        viewModel.draftMessageText = "Hi! I'm interested in buying your \(viewModel.chatInfo?.listing.title ?? "item"), but would you be open to selling it for $\(priceText)?"
        priceText = ""
    }
}

// MARK: - Filter Options View

struct FilterOptionsView: View {
    @Binding var didShowNegotiationView: Bool
    @Binding var didShowAvailabilityView: Bool
    @Binding var didShowWebView: Bool
    @Binding var isEditing: Bool
    let viewModel: MessagesView.ViewModel

    var body: some View {
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
                            isEditing = true
                            withAnimation { didShowAvailabilityView = true }
                        }
                    case .venmo:
                        chatOption(title: option.rawValue) {
                            withAnimation { didShowWebView = true }
                        }
                    case .viewAvailability:
                        chatOption(title: "View \(viewModel.chatInfo?.listing.user?.givenName ?? "")'s Availability") {
                            isEditing = false
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
}

// MARK: - Negotiation Sheet View

struct NegotiationSheetView: View {
    let chatInfo: ChatInfo?
    @Binding var priceText: String
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                KFImage(chatInfo?.listing.images[0])
                    .placeholder {
                        ShimmerView()
                            .frame(width: 128, height: 100)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 128, height: 100)
                    .clipShape(.rect(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 8) {
                    Text(chatInfo?.listing.title ?? "")
                        .font(Constants.Fonts.h2)
                        .foregroundStyle(Constants.Colors.black)

                    Text("$\(chatInfo?.listing.originalPrice ?? "0")")
                        .font(Constants.Fonts.body1)
                        .foregroundStyle(Constants.Colors.black)
                }

                Spacer()
            }
            .padding(16)
            .frame(width: UIScreen.width - 40, height: 125)
            .background(Constants.Colors.white)
            .clipShape(.rect(cornerRadius: 18))

            PriceInputView(
                price: $priceText,
                isPresented: $isPresented,
                titleText: "What price do you want to propose?"
            )
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
}



// MARK: - MessageBubbleView

struct MessageBubbleView: View {

    @Binding var didShowAvailabilityView: Bool
    @Binding var isEditing: Bool
    @Binding var selectedAvailabilities: [Availability]

    let message: Message
    let messageLocation: MessageLocation

    private var fromUser: Bool {
        return messageLocation == .right
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: messageLocation.alignment) {
                messageContentView
            }
        }
        .padding(.horizontal, UIScreen.width / 4)
    }

    @ViewBuilder
    private var messageContentView: some View {
        switch message.messageType {
        case .chat:
            chatMessageView
        case .availability:
            availabilityMessageView
        case .proposal:
            proposalMessageView
        }
    }

    @ViewBuilder
    private var chatMessageView: some View {
        if let message = message as? ChatMessage {
            VStack {
                textBubbleView(message: message)
                ForEach(message.images, id: \.self) { image in
                    imageView(imageUrl: image)
                }
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func textBubbleView(message: ChatMessage) -> some View {
        HStack {
            if fromUser {
                Spacer()
            }

            VStack(alignment: fromUser ? .trailing : .leading, spacing: 8) {
                Text(message.text)
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(fromUser ? Constants.Colors.white : Constants.Colors.black)

                Text(message.timestamp.description)
                    .font(.caption2)
                    .foregroundStyle(fromUser ? Constants.Colors.white : Constants.Colors.secondaryGray)
            }
            .padding(12)
            .background(fromUser ? Constants.Colors.resellPurple : Constants.Colors.wash)
            .foregroundColor(fromUser ? Constants.Colors.white : Constants.Colors.black)
            .cornerRadius(10)

            if !fromUser {
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func imageView(imageUrl: String) -> some View {
        HStack {
            if fromUser {
                Spacer()
            }

            if let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } placeholder: {
                    ProgressView()
                }
            }

            if !fromUser {
                Spacer()
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var availabilityMessageView: some View {
        if let message = message as? AvailabilityMessage {
            Button {
                selectedAvailabilities = message.availabilities
                didShowAvailabilityView = true
                isEditing = false
            } label: {
                HStack {
                    Text("\(message.from.givenName)'s Availability")
                        .font(Constants.Fonts.title2)
                        .foregroundStyle(Constants.Colors.resellPurple)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(Constants.Colors.resellPurple)
                }
                .padding(12)
                .background(Constants.Colors.resellPurple.opacity(0.1))
                .clipShape(.rect(cornerRadius: 10))
                .padding(.vertical, 6)
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var proposalMessageView: some View {
        if let message = message as? ProposalMessage {
            Text("Proposal!")
                .font(Constants.Fonts.subtitle1)
                .foregroundColor(Constants.Colors.secondaryGray)
        } else {
            EmptyView()
        }
    }

}



// MARK: - TextInputView

struct TextInputView: View {

    // MARK: - Properties

    @State private var selectedImages: [UIImage] = []
    @State private var showingPhotoPicker = false
    @Binding var draftMessageText: String

    let onSend: (String?, [UIImage]?) -> Void
    let maxCharacters: Int = 1000

    // MARK: - UI

    var body: some View {
        VStack(spacing: 8) {
            // Image preview section
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<selectedImages.count, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                Button(action: {
                                    selectedImages.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .shadow(radius: 2)
                                        .padding(4)
                                }
                            }
                        }
                    }
                    .padding(.leading, 32)
                }
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
                    ImagePicker(selectedImages: $selectedImages)
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

                if !draftMessageText.isEmpty || !selectedImages.isEmpty {
                    Button(action: {
                        onSend(draftMessageText.isEmpty ? nil : draftMessageText, selectedImages.isEmpty ? nil : selectedImages)
                        draftMessageText = ""
                        selectedImages = []
                    }) {
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
