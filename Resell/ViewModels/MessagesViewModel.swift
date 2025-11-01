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

            Task { [weak self] in
                guard let self else { return }

                chatInfo = try await simpleChatInfo.toChatInfo()
            }
        }

        /// Subscribe to chat updates for this chat, needs a chatId before it can be subscribed to
        func subscribeToChat() {
            guard let chatId = self.chatId else { return }

            FirestoreManager.shared.subscribeToChat(chatId) { [weak self] chats in
                guard !chats.isEmpty, let chat = chats.first, let self else { return }

                messageClusters = clusterMessages(chat.messages)
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
            guard let user = GoogleAuthManager.shared.user else { return }

            var imageURLs: [String] = []

            for image in imagesBase64 {
                let url = try await uploadImage(imageBase64: image)
                imageURLs.append(url)
            }

            let chatId = getOrCreateChatId()

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
        }

        /// Send a chat message contain text, images, or both
        func sendMessage(text: String? = nil, imagesBase64: [String]? = nil) async throws {
            // At least one cant be empty
            guard let text = text, let imagesBase64 = imagesBase64, !text.isEmpty || !imagesBase64.isEmpty else { return }

            try await self.sendGenericMessage(text: text, imagesBase64: imagesBase64)
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
            guard let currentUserId = GoogleAuthManager.shared.user?.firebaseUid else { return [] }

            var clusters: [MessageCluster] = []
            var currentBatch: [Message] = []
            var lastSenderId: String? = nil

            for message in messages {
                // If sender changed, create a new cluster with accumulated messages
                if let lastId = lastSenderId, lastId != message.from.firebaseUid, let first = currentBatch.first {
                    let isFromCurrentUser = lastId == currentUserId
                    clusters.append(
                        MessageCluster(
                            id: UUID().uuidString,
                            sender: .user(user: first.from),
                            location: isFromCurrentUser ? .right : .left,
                            messages: currentBatch
                        )
                    )
                    currentBatch = []
                }

                // Add message to current batch
                currentBatch.append(message)
                lastSenderId = message.from.firebaseUid
            }

            // Don't forget the last batch
            if let lastId = lastSenderId, let first = currentBatch.first {
                let isFromCurrentUser = lastId == currentUserId
                clusters.append(
                    MessageCluster(
                        id: UUID().uuidString,
                        sender: .user(user: first.from),
                        location: isFromCurrentUser ? .right : .left,
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
        private func getOrCreateChatId() -> String {
            let chatId = self.chatId ?? UUID().uuidString
            self.chatId = chatId
            return chatId
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
