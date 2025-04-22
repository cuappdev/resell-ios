//
//  MessagesViewModel.swift
//  Resell
//
//  Created by Peter Bidoshi on 2/26/25.
//

import Foundation

extension MessagesView {

    class ViewModel: ObservableObject {

        @Published var availability: [Availability] = []
        @Published var didShowNegotiationView = false
        @Published var didShowAvailabilityView = false
        @Published var didShowWebView = false
        @Published var draftMessageText = ""
        @Published var messageClusters: [MessageCluster] = []
        @Published var venmoURL: URL?

        let simpleChatInfo: SimpleChatInfo
        var chatId: String?
        @Published var chatInfo: ChatInfo?

        init(simpleChatInfo: SimpleChatInfo) {
            self.simpleChatInfo = simpleChatInfo
        }

        /// Subscribe to chat updates for this chat, needs a chatId before it can be subscribed to
        func subscribeToChat() {
            guard let chatId else { return }

            FirestoreManager.shared.subscribeToChat(chatId) { [weak self] chats in
                guard !chats.isEmpty, let chat = chats.first, let self else { return }

                Task {
                    await MainActor.run { [weak self] in
                        guard let self else { return }

                        messageClusters = clusterMessages(chat.messages)
                    }
                }
            }
        }

        /// send a generic message with potential for all fields
        private func sendGenericMessage(
            text: String? = nil,
            imagesBase64: [String] = [],
            availabilities: [Availability] = [],
            startDate: Date? = nil,
            endDate: Date? = nil
        ) async throws {
            guard let user = GoogleAuthManager.shared.user, let chatId = self.chatId else { return }

            var imageURLs: [String] = []

            for image in imagesBase64 {
                let url = try await uploadImage(imageBase64: image)
                imageURLs.append(url)
            }

            let messageBody = MessageBody(
                type: .chat,
                listingId: simpleChatInfo.listingId,
                buyerId: simpleChatInfo.buyerId,
                sellerId: simpleChatInfo.sellerId,
                senderId: user.firebaseUid,
                text: text,
                images: imageURLs,
                availabilities: availabilities,
                startDate: startDate,
                endDate: endDate
            )

            try await NetworkManager.shared.sendMessage(chatId: chatId, messageBody: messageBody)

            if FirestoreManager.shared.listener == nil {
                subscribeToChat()
            }
        }

        /// Send a chat message contain text, images, or both
        func sendMessage(text: String? = nil, imagesBase64: [String]? = nil) async throws {
            guard let user = GoogleAuthManager.shared.user else { return }
            let otherUser = simpleChatInfo.buyerId == user.firebaseUid ? simpleChatInfo.sellerId : simpleChatInfo.buyerId

            // At least one cant be empty
            let unwrappedText = text ?? ""
            let unwrappedImages = imagesBase64 ?? []
            guard !unwrappedText.isEmpty || !unwrappedImages.isEmpty else { return }

            Task {
                await MainActor.run {
                    var addedToACluster = false
                    if var lastCluster = messageClusters.last, let lastMessage = lastCluster.messages.last {
                        if lastMessage.timestamp.addingTimeInterval(3600) >= Date() {
                            lastCluster.messages.append(ChatMessage(timestamp: Date(), read: false, fromUser: true, confirmed: false, text: unwrappedText, images: unwrappedImages))
                            messageClusters[messageClusters.count - 1] = lastCluster // Replace the last cluster
                            addedToACluster = true
                        }
                    }

                    if !addedToACluster {
                        messageClusters.append(MessageCluster(id: UUID().uuidString, location: .right, messages: [ChatMessage(timestamp: Date(), read: false, fromUser: true, confirmed: false, text: unwrappedText, images: unwrappedImages)]))
                    }
                }
            }

            try await self.sendGenericMessage(text: unwrappedText, imagesBase64: unwrappedImages)
        }

        /// Send an availability message
        func sendMessage(availability: [Availability]) async throws {
            // Make sure there is at least one availability
            guard !availability.isEmpty else { return }

            try await self.sendGenericMessage(availabilities: availability)
        }

        /// Send a proposal message
        func sendMessage(startDate: Date, endDate: Date) async throws {
            try await self.sendGenericMessage(startDate: startDate, endDate: endDate)
        }

        // MARK: - Helper Functions

        /// Cluster messages by sender
        private func clusterMessages(_ messages: [Message]) -> [MessageCluster] {
            // Sort messages by timestamp
            let sortedMessages = messages.sorted(by: { $0.timestamp < $1.timestamp })

            var clusters: [MessageCluster] = []
            var currentBatch: [Message] = []
            var lastSenderIsUser: Bool? = nil
            var lastMessageTimestamp: Date? = nil

            for message in sortedMessages {
                // Check if we should create a new cluster:
                // 1. If sender changed (isUser changed)
                // 2. If time difference > 60 minutes (3600 seconds)
                let shouldCreateNewCluster =
                (lastSenderIsUser != nil && lastSenderIsUser != message.fromUser) ||
                    (lastMessageTimestamp != nil &&
                     message.timestamp.timeIntervalSince(lastMessageTimestamp!) > 3600)

                if shouldCreateNewCluster, !currentBatch.isEmpty, let first = currentBatch.first {
                    clusters.append(
                        MessageCluster(
                            id: UUID().uuidString,
                            location: first.fromUser ? .right : .left,
                            messages: currentBatch
                        )
                    )

                    currentBatch = []
                }

                // Add message to current batch
                currentBatch.append(message)
                lastSenderIsUser = message.fromUser
                lastMessageTimestamp = message.timestamp
            }

            // Don't forget the last batch
            if !currentBatch.isEmpty, let first = currentBatch.first {
                clusters.append(
                    MessageCluster(
                        id: UUID().uuidString,
                        location: first.fromUser ? .right : .left,
                        messages: currentBatch
                    )
                )
            }

            return clusters
        }

        /// Upload the image and return the URL
        private func uploadImage(imageBase64: String) async throws -> String {
            let requestBody = ImageBody(imageBase64: imageBase64)
            let response = try await NetworkManager.shared.uploadImage(image: requestBody)

            return response.image
        }

        /// Get the post id from the chat if it exists
        func getOrCreateChatId() async throws {
            let chatId = try await FirestoreManager.shared.findChatId(listingId: simpleChatInfo.listingId, buyerId: simpleChatInfo.buyerId, sellerId: simpleChatInfo.sellerId)


            self.chatId = chatId ?? UUID().uuidString
        }

        /// Parse the Venmo URL
        func parsePayWithVenmoURL() {
            guard let user = GoogleAuthManager.shared.user, let chatInfo = chatInfo else {
                GoogleAuthManager.shared.logger.error("Error in \(#file) \(#function): One or both users not available.")
                return
            }

            let otherUser = chatInfo.buyer.firebaseUid == user.firebaseUid ? chatInfo.seller : chatInfo.buyer
            let venmoHandle = otherUser.venmoHandle

            let url = URL(string: "https://account.venmo.com/u/\(venmoHandle)")
            self.venmoURL = url
        }

    }

}
