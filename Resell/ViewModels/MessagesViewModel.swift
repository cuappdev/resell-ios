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

        var chatId: String?
        @Published var chatInfo: ChatInfo

        init(chatInfo: ChatInfo) {
            self.chatInfo = chatInfo
        }

        /// Subscribe to chat updates for this chat, needs a chatId before it can be subscribed to
        func subscribeToChat() {
            guard let chatId else { return }

            FirestoreManager.shared.subscribeToChat(chatId) { [weak self] chats in
                guard !chats.isEmpty, let chat = chats.first, let self else { return }
                // Mark read to all new messages from the other person that aren't read
                let unreadMessages = chat.messages.filter { !$0.read && !$0.mine }

                // Mark messages as read, asynchronously in the background
                Task.detached(priority: .background) {
                    for message in unreadMessages {
                        // Check for cancellation between iterations
                        if Task.isCancelled { break }

                        do {
                            try await self.markMessageAsRead(chatId: chatId, message: message)
                        } catch {
                            NetworkManager.shared.logger.error("Error: Unable to mark message as read: \(error)")
                        }
                    }
                }

                Task {
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        messageClusters = clusterMessages(chat.messages)
                    }
                }
            }
        }

        /// mark a message as read
        private func markMessageAsRead(chatId: String, message: any Message) async throws {
            guard message.mine == false, !message.read else { return }

            let _ = try await NetworkManager.shared.markMessageRead(chatId: chatId, messageId: message.messageId)
        }

        /// send a generic message with potential for all fields
        private func sendGenericMessage(
            text: String? = nil,
            imagesBase64: [String]? = nil,
            availabilities: [Availability]? = nil,
            startDate: Date? = nil,
            endDate: Date? = nil
        ) async throws {
            guard let user = GoogleAuthManager.shared.user, let chatId = self.chatId else { return }

            var imageURLs: [String] = []

            if let images = imagesBase64 {
                for image in images {
                    let url = try await uploadImage(imageBase64: image)
                    imageURLs.append(url)
                }
            }

            let type: MessageType
            if !(text?.isEmpty ?? true) || !imageURLs.isEmpty {
                type = .chat
            } else if let availabilities, !availabilities.isEmpty {
                type = .availability
            } else if startDate != nil && endDate != nil {
                type = .proposal
            } else {
                type = .chat
            }

            let messageBody = MessageBody(
                type: type,
                listingId: chatInfo.listing.id,
                buyerId: chatInfo.buyer.firebaseUid,
                sellerId: chatInfo.seller.firebaseUid,
                senderId: user.firebaseUid,
                text: text,
                images: imageURLs,
                availabilities: availabilities,
                startDate: startDate,
                endDate: endDate
            )

            switch type {
            case .chat:
                try await NetworkManager.shared.sendChatMessage(chatId: chatId, messageBody: messageBody)
            case .availability:
                try await NetworkManager.shared.sendChatAvailability(chatId: chatId, messageBody: messageBody)
            default:
                // TODO: bad type
                break
            }


        }

        /// Send a chat message contain text, images, or both
        func sendMessage(text: String? = nil, imagesBase64: [String]? = nil) async throws {
            guard let user = GoogleAuthManager.shared.user else { return }

            // At least one cant be empty
            let unwrappedText = text ?? ""
            let unwrappedImages = imagesBase64 ?? []
            guard !unwrappedText.isEmpty || !unwrappedImages.isEmpty else { return }

            // Create the new message with "sending" state
            let newMessage = ChatMessage(
                messageId: UUID().uuidString,
                timestamp: Date(),
                read: false,
                mine: true,
                from: user,
                sent: false,  // False indicates "sending" state
                text: unwrappedText,
                images: unwrappedImages
            )

            Task {
                await MainActor.run {
                    var addedToLastCluster = false

                    // Check if we should add to the last cluster
                    if var lastCluster = messageClusters.last,
                       let lastMessage = lastCluster.messages.last,
                       Calendar.current.isDate(newMessage.timestamp, inSameDayAs: lastMessage.timestamp) {

                        // Add to existing cluster if it's from the same day
                        lastCluster.messages.append(newMessage)
                        messageClusters[messageClusters.count - 1] = lastCluster
                        addedToLastCluster = true
                    }

                    // Create a new cluster if needed
                    if !addedToLastCluster {
                        messageClusters.append(
                            MessageCluster(
                                location: .right,
                                messages: [newMessage]
                            )
                        )
                    }
                }
            }

            // Actually send the message (this will happen in parallel with UI update)
            try await self.sendGenericMessage(text: unwrappedText, imagesBase64: unwrappedImages)
        }

        /// Send an availability message
        func sendMessage(availability: [Availability]) async throws {
            try await self.sendGenericMessage(availabilities: availability)
        }

        /// Send a proposal message
        func sendMessage(startDate: Date, endDate: Date) async throws {
            try await self.sendGenericMessage(startDate: startDate, endDate: endDate)
        }

        // MARK: - Helper Functions

        /// Cluster messages by sender
        private func clusterMessages(_ messages: [any Message]) -> [MessageCluster] {
            // Sort messages by timestamp
            let sortedMessages = messages.sorted(by: { $0.timestamp < $1.timestamp })

            var clusters: [MessageCluster] = []
            var currentBatch: [any Message] = []
            var lastMessageTimestamp: Date? = nil

            for message in sortedMessages {
                // Check if we should create a new cluster:
                // 1. If its a new day
                let shouldCreateNewCluster = lastMessageTimestamp == nil ||
                !Calendar.current.isDate(message.timestamp, inSameDayAs: lastMessageTimestamp!)
                if shouldCreateNewCluster, !currentBatch.isEmpty, let first = currentBatch.first {
                    clusters.append(
                        MessageCluster(
                            location: first.mine ? .right : .left,
                            messages: currentBatch
                        )
                    )

                    currentBatch = []
                }

                // Add message to current batch
                currentBatch.append(message)
                lastMessageTimestamp = message.timestamp
            }

            // Don't forget the last batch
            if !currentBatch.isEmpty, let first = currentBatch.first {
                clusters.append(
                    MessageCluster(
                        location: first.mine ? .right : .left,
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
            let chatId = try await FirestoreManager.shared.findChatId(listingId: chatInfo.listing.id, buyerId: chatInfo.buyer.firebaseUid, sellerId: chatInfo.seller.firebaseUid)


            self.chatId = chatId ?? UUID().uuidString
        }

        /// Parse the Venmo URL
        func parsePayWithVenmoURL() {
            guard let user = GoogleAuthManager.shared.user else {
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
