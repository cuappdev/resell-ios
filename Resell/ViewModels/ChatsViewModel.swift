//
//  ChatsViewModel.swift
//  Resell
//
//  Created by Richie Sun on 10/26/24.
//

import Firebase
import FirebaseFirestore
import SwiftUI

@MainActor
class ChatsViewModel: ObservableObject {

    // MARK: - Properties

    @Published var isLoading: Bool = false

    @Published var purchaseChats: [ChatPreview] = []
    @Published var offerChats: [ChatPreview] = []

    @Published var purchaseUnread: Int = 0
    @Published var offerUnread: Int = 0

    @Published var selectedChat: ChatPreview? = nil

    @Published var buyersHistory: [TransactionSummary] = []
    @Published var sellersHistory: [TransactionSummary] = []
    @Published var subscribedChat: Chat?
    @Published var selectedTab: String = "Purchases"

    @Published var draftMessageText: String = ""

    private let firestoreManager = FirestoreManager.shared

    // MARK: - Functions

    func getAllChats() {
        getPurchaceChats()
        getOfferChats()
    }

    func getPurchaceChats() {
        isLoading = true

        firestoreManager.getPurchaseChats { [weak self] purchaseChats in
            guard let self else { return }

            self.purchaseChats = purchaseChats
            purchaseUnread = countUnviewedChats(chats: purchaseChats)
            isLoading = false
        }
    }

    func getOfferChats() {
        isLoading = true

        firestoreManager.getOfferChats { [weak self] offerChats in
            guard let self else { return }

            self.offerChats = offerChats
            offerUnread = countUnviewedChats(chats: offerChats)
            isLoading = false
        }
    }

    func countUnviewedChats(chats: [ChatPreview]) -> Int {
        return chats.filter { !$0.viewed }.count
    }

    func updateChatViewed() {
        guard let userEmail = UserSessionManager.shared.email,
              let chatID = selectedChat?.id else { return }
        firestoreManager.updateChatViewedStatus(chatType: selectedTab, userEmail: userEmail, chatId: chatID, isViewed: true)
    }

    /// Fetch seller's transaction history
    func fetchSellersHistory() {
        guard let userEmail = UserSessionManager.shared.email else {
            FirestoreManager.shared.logger.error("User email not found in UserSessionManager.")
            return
        }

        Task {
            do {
                let sellerData = try await firestoreManager.getSellerHistory(email: userEmail)
                self.sellersHistory = sellerData
            } catch {
                FirestoreManager.shared.logger.error("Error fetching seller history for \(userEmail): \(error.localizedDescription)")
            }
        }
    }

    /// Fetch buyer's transaction history
    func fetchBuyersHistory() {
        guard let userEmail = UserSessionManager.shared.email else {
            FirestoreManager.shared.logger.error("User email not found in UserSessionManager.")
            return
        }

        Task {
            do {
                let buyerData = try await firestoreManager.getBuyerHistory(email: userEmail)
                self.buyersHistory = buyerData
            } catch {
                FirestoreManager.shared.logger.error("Error fetching buyer history for \(userEmail): \(error.localizedDescription)")
            }
        }
    }

    /// Subscribe to chat updates
    func subscribeToChat(myEmail: String, otherEmail: String, selfIsBuyer: Bool) {
        firestoreManager.subscribeToChat(
            buyerEmail: selfIsBuyer ? myEmail : otherEmail,
            sellerEmail: selfIsBuyer ? otherEmail : myEmail
        ) { [weak self] documents in
            guard let self = self else { return }

            let messageData = documents.map { document -> (ChatMessageData, Bool) in
                let messageType: MessageType = {
                    if !document.image.isEmpty { return .image }
                    if document.availability != nil { return .availability }
                    if document.product != nil { return .card }
                    return .message
                }()
                return (
                    ChatMessageData(
                        id: document.id,
                        timestamp: document.createdAt,
                        content: document.text,
                        messageType: messageType,
                        imageUrl: document.image,
                        post: document.product
                    ),
                    document.user.id == myEmail
                )
            }

            // Process the chat data
            let messageClusters = self.clusterMessages(messageData)
            let dateStateClusters = self.addDateStates(to: messageClusters)
            self.subscribedChat = Chat(history: dateStateClusters)
        }
    }

    /// Send a text message
    func sendTextMessage(
        myEmail: String,
        otherEmail: String,
        text: String,
        selfIsBuyer: Bool,
        postId: String
    ) {
        Task {
            do {
                guard let imageUrl = UserSessionManager.shared.profileURL,
                      let name = UserSessionManager.shared.name else { return }
                let userDocument = UserDocument(id: myEmail, avatar: imageUrl, name: name)
                let chatDocument = ChatDocument(
                    id: UUID().uuidString,
                    createdAt: Timestamp(date: Date()),
                    image: "",
                    text: text,
                    user: userDocument,
                    availability: nil,
                    product: nil
                )

                try await firestoreManager.sendTextMessage(
                    buyerEmail: selfIsBuyer ? myEmail : otherEmail,
                    sellerEmail: selfIsBuyer ? otherEmail : myEmail,
                    chatDocument: chatDocument
                )
            } catch {
                FirestoreManager.shared.logger.error("Error sending text message: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Helper Functions

    /// Cluster messages by sender
    private func clusterMessages(
        _ messageData: [(ChatMessageData, Bool)]
    ) -> [ChatMessageCluster] {
        var clusters: [ChatMessageCluster] = []
        var currentMessages: [ChatMessageData] = []
        var currentFromUser: Bool?

        for (message, fromUser) in messageData {
            if fromUser != currentFromUser {
                if !currentMessages.isEmpty {
                    clusters.append(
                        ChatMessageCluster(
                            senderId: currentFromUser == true ? "self" : "other",
                            senderImage: nil,
                            fromUser: currentFromUser ?? false,
                            messages: currentMessages
                        )
                    )
                }
                currentMessages = [message]
                currentFromUser = fromUser
            } else {
                currentMessages.append(message)
            }
        }

        if !currentMessages.isEmpty {
            clusters.append(
                ChatMessageCluster(
                    senderId: currentFromUser == true ? "self" : "other",
                    senderImage: nil,
                    fromUser: currentFromUser ?? false,
                    messages: currentMessages
                )
            )
        }

        return clusters
    }

    /// Add date states to message clusters
    private func addDateStates(to clusters: [ChatMessageCluster]) -> [ChatMessageCluster] {
        var lastTimestamp: Date = Date.distantPast

        return clusters.map { cluster in
            var newMessages = cluster.messages
            for (index, message) in cluster.messages.enumerated() {
                let messageDate = message.timestamp.dateValue()
                if !Calendar.current.isDate(messageDate, inSameDayAs: lastTimestamp) {
                    let dateMessage = ChatMessageData(
                        id: UUID().uuidString,
                        timestamp: message.timestamp,
                        content: messageDate.toFormattedString(),
                        messageType: .state,
                        imageUrl: "",
                        post: nil
                    )
                    newMessages.insert(dateMessage, at: index)
                }
                lastTimestamp = messageDate
            }
            return ChatMessageCluster(
                senderId: cluster.senderId,
                senderImage: cluster.senderImage,
                fromUser: cluster.fromUser,
                messages: newMessages
            )
        }
    }
}
