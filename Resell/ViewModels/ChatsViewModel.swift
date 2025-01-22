//
//  ChatsViewModel.swift
//  Resell
//
//  Created by Richie Sun on 10/26/24.
//

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
    @Published var selectedPost: Post? = nil

    @Published var buyersHistory: [TransactionSummary] = []
    @Published var sellersHistory: [TransactionSummary] = []
    @Published var subscribedChat: Chat?
    @Published var selectedTab: String = "Purchases"

    @Published var draftMessageText: String = ""
    @Published var availabilityDates: [AvailabilityBlock] = []

    @Published var otherUserProfileImage: UIImage = UIImage(named: "emptyProfile")!

    private let firestoreManager = FirestoreManager.shared
    private var blockedUsers: [String] = []

    var otherUser: User?
    var venmoURL: URL?

    // MARK: - Functions

    func checkEmptyState() -> Bool {
        if selectedTab == "Purchases" {
            return purchaseChats.isEmpty
        } else {
            return offerChats.isEmpty
        }
    }

    func emptyStateTitle() -> String {
        return "No messages with \(selectedTab == "Purchases" ? "Sellers" : "Buyers") yet"
    }

    func emptyStateMessage() -> String {
        return selectedTab == "Purchases" ? "When you contact a seller, you’ll see your messages here" : "When a buyer contacts you, you’ll see their messages here"
    }

    func getAllChats() {
        Task {
            isLoading = true

            do {
                if let userID = UserSessionManager.shared.userID {
                    blockedUsers = try await NetworkManager.shared.getBlockedUsers(id: userID).users.map { $0.email }

                    getPurchaceChats()
                    getOfferChats()
                } else {
                    UserSessionManager.shared.logger.error("Error in BlockedUsersView: userID not found.")
                }
            } catch {
                NetworkManager.shared.logger.error("Error in BlockedUsersView: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }

    func getPurchaceChats() {
        isLoading = true

        firestoreManager.getPurchaseChats { [weak self] purchaseChats in
            guard let self else { return }

            self.purchaseChats = purchaseChats.filter { !self.blockedUsers.contains($0.email) }
            purchaseUnread = countUnviewedChats(chats: self.purchaseChats)
            withAnimation { self.isLoading = false }
        }
    }

    func getOfferChats() {
        isLoading = true

        firestoreManager.getOfferChats { [weak self] offerChats in
            guard let self else { return }

            self.offerChats = offerChats.filter { !self.blockedUsers.contains($0.email) }
            offerUnread = countUnviewedChats(chats: self.offerChats)
            withAnimation { self.isLoading = false }
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

    func getSelectedChatPost(completion: @escaping (Post) -> Void) {
        isLoading = true

        if let itemID = selectedChat?.recentItem["id"] as? String {
            Task {
                do {
                    let postResponse = try await NetworkManager.shared.getPostByID(id: itemID)
                    isLoading = false
                    selectedPost = postResponse.post

                    completion(postResponse.post)
                } catch {
                    NetworkManager.shared.logger.error("Error in ChatsViewModel.getSelectedChatPost: \(error.localizedDescription)")
                    isLoading = false
                }
            }
        }
    }

    func getOtherUser(email: String) {
        Task {
            do {
                let userResponse = try await NetworkManager.shared.getUserByEmail(email: email)
                otherUser = userResponse.user

                guard let url = otherUser?.photoUrl else { return }
                let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                    guard let data, let uiImage = UIImage(data: data) else { return }
                    DispatchQueue.main.async {
                        self?.otherUserProfileImage = uiImage
                    }
                }
                task.resume()
            } catch {
                NetworkManager.shared.logger.error("Error in ChatsViewModel.getOtherUser: \(error)")
            }
        }
    }

    func parsePayWithVenmoURL(email: String) {
        Task {
            do {
                let venmoHandle = try await firestoreManager.getVenmoHandle(email: email)
                let url = URL(string: "https://account.venmo.com/u/\(venmoHandle)")
                venmoURL = url
            } catch {
                firestoreManager.logger.error("Error in ChatsViewModel.parsePayWithVenmoURL: \(error)")
            }
        }
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
                    if !document.image.isEmpty {
                        return .image
                    } else if !document.text.isEmpty {
                        return .message
                    } else if document.availability != nil {
                        return .availability
                    } else if document.meetingInfo != nil {
                        return .state
                    } else if document.product != nil {
                        return .card
                    }

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
        senderEmail: String,
        recipientEmail: String,
        senderName: String,
        recipientName: String,
        senderImageUrl: URL,
        recipientImageUrl: URL,
        messageText: String,
        isBuyer: Bool,
        postId: String
    ) async throws {
        try await sendGenericMessage(
            senderEmail: senderEmail,
            recipientEmail: recipientEmail,
            senderName: senderName,
            recipientName: recipientName,
            senderImageUrl: senderImageUrl,
            recipientImageUrl: recipientImageUrl,
            isBuyer: isBuyer,
            postId: postId,
            messageText: messageText
        )
    }

    /// Send an image message
    func sendImageMessage(
        senderEmail: String,
        recipientEmail: String,
        senderName: String,
        recipientName: String,
        senderImageUrl: URL,
        recipientImageUrl: URL,
        imageBase64: String,
        isBuyer: Bool,
        postId: String
    ) async throws {
        let url = try await uploadImage(imageBase64: imageBase64)

        // Send the generic message with the uploaded image URL
        try await sendGenericMessage(
            senderEmail: senderEmail,
            recipientEmail: recipientEmail,
            senderName: senderName,
            recipientName: recipientName,
            senderImageUrl: senderImageUrl,
            recipientImageUrl: recipientImageUrl,
            isBuyer: isBuyer,
            postId: postId,
            imageUrl: url
        )
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
            guard !cluster.messages.isEmpty else { return cluster }

            var newMessages: [ChatMessageData] = []

            for message in cluster.messages {
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
                    newMessages.append(dateMessage)
                }

                newMessages.append(message)

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

    /// Upload the image and return the URL
    private func uploadImage(imageBase64: String) async throws -> String {
        let requestBody = ImageBody(imageBase64: imageBase64)
        let response = try await NetworkManager.shared.uploadImage(image: requestBody)

        return response.image
    }
}

// MARK: - ChatsViewModel: Message Functions

extension ChatsViewModel {
    func sendGenericMessage(
        senderEmail: String,
        recipientEmail: String,
        senderName: String,
        recipientName: String,
        senderImageUrl: URL,
        recipientImageUrl: URL,
        isBuyer: Bool,
        postId: String,
        imageUrl: String? = nil,
        messageText: String? = nil,
        availability: AvailabilityDocument? = nil,
        meetingInfo: MeetingInfo? = nil
    ) async throws {
        let currentTimeMillis = Int(Date().timeIntervalSince1970 * 1000)

        let buyerEmail = isBuyer ? senderEmail : recipientEmail
        let sellerEmail = isBuyer ? recipientEmail : senderEmail
        let buyerName = isBuyer ? senderName : recipientName
        let sellerName = isBuyer ? recipientName : senderName
        let buyerImageUrl = isBuyer ? senderImageUrl : recipientImageUrl
        let sellerImageUrl = isBuyer ? recipientImageUrl : senderImageUrl
        let timestamp = Timestamp()

        let isoDateFormatter = ISO8601DateFormatter()
        isoDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        isoDateFormatter.timeZone = TimeZone.current
        let isoFormattedDate = isoDateFormatter.string(from: timestamp.dateValue())

        let senderDocument = UserDocument(_id: senderEmail, avatar: senderImageUrl, name: senderName)

        let chatDocumentSendable = ChatDocumentSendable(
            _id: UUID().uuidString,
            createdAt: timestamp,
            user: senderDocument,
            availability: [:],
            product: [:],
            image: imageUrl ?? "",
            text: messageText ?? "",
            meetingInfo: meetingInfo
        )

        let chatDocument = ChatDocument(
            _id: "\(currentTimeMillis)",
            createdAt: timestamp,
            user: senderDocument,
            availability: availability,
            product: nil,
            image: imageUrl ?? "",
            text: messageText ?? "",
            meetingInfo: meetingInfo
        )

        guard let post = selectedPost else { return }

        if subscribedChat?.history.isEmpty ?? true {
            try await firestoreManager.sendProductMessage(
                buyerEmail: buyerEmail,
                sellerEmail: sellerEmail,
                otherDocument: chatDocument,
                post: post
            )
        }

        try await firestoreManager.sendChatMessage(buyerEmail: buyerEmail, sellerEmail: sellerEmail, chatDocument: chatDocumentSendable)

        let recentMessage = determineRecentMessage(
            text: messageText,
            imageUrl: imageUrl,
            availability: availability,
            meetingInfo: meetingInfo
        )

        let notificationText = determineNotificationText(
            text: messageText,
            imageUrl: imageUrl,
            availability: availability,
            meetingInfo: meetingInfo
        )

        print(post.title)

        let sellerData = TransactionSummary(
            item: post,
            recentMessage: recentMessage,
            recentMessageTime: isoFormattedDate,
            recentSender: senderName,
            confirmedTime: "",
            confirmedViewed: false,
            name: sellerName,
            image: sellerImageUrl,
            viewed: isBuyer
        )

        let buyerData = TransactionSummary(
            item: post,
            recentMessage: recentMessage,
            recentMessageTime: timestamp.dateValue().iso8601String,
            recentSender: senderName,
            confirmedTime: "",
            confirmedViewed: false,
            name: buyerName,
            image: buyerImageUrl,
            viewed: !isBuyer
        )

        print(isBuyer)

        try await firestoreManager.updateBuyerHistory(sellerEmail: sellerEmail, buyerEmail: buyerEmail, data: buyerData)
        try await firestoreManager.updateSellerHistory(buyerEmail: buyerEmail, sellerEmail: sellerEmail, data: sellerData)
        try await firestoreManager.updateItems(email: buyerEmail, postId: postId, post: post)

        if let token = try await firestoreManager.getUserFCMToken(email: recipientEmail) {

            try await FirebaseNotificationService.shared.sendNotification(title: senderName, body: notificationText, recipientToken: token, navigationId: "", authToken: UserSessionManager.shared.oAuthToken ?? "")
        }
    }

    // MARK: - Helper Functions

    private func determineRecentMessage(
        text: String?,
        imageUrl: String?,
        availability: AvailabilityDocument?,
        meetingInfo: MeetingInfo?
    ) -> String {
        if let text = text { return text }
        if let _ = imageUrl { return "[Image]" }
        if let _ = availability { return "[Availability]" }
        if let meetingInfo = meetingInfo {
            switch meetingInfo.state {
            case "proposed": return "Proposed a Meeting"
            case "confirmed": return "Accepted a Meeting!"
            case "declined": return "Declined a Meeting"
            case "canceled": return "Canceled a Meeting"
            default: return "Updated Meeting Details"
            }
        }
        return ""
    }

    private func determineNotificationText(
        text: String?,
        imageUrl: String?,
        availability: AvailabilityDocument?,
        meetingInfo: MeetingInfo?
    ) -> String {
        if let text = text { return text }
        if let _ = imageUrl { return "Sent an Image" }
        if let _ = availability { return "Sent their Availability" }
        if let meetingInfo = meetingInfo {
            switch meetingInfo.state {
            case "proposed": return "Proposed a Meeting"
            case "confirmed": return "Accepted a Meeting!"
            case "declined": return "Declined a Meeting"
            case "canceled": return "Canceled a Meeting"
            default: return "Updated Meeting Details"
            }
        }
        return ""
    }

}
