//
//  FirestoreManager.swift
//  Resell
//
//  Created by Richie Sun on 11/29/24.
//

import FirebaseFirestore
import os
import FirebaseVertexAI

class FirestoreManager {

    // MARK: - Singleton Instance

    static let shared = FirestoreManager()

    // MARK: - Init

    private init() { }

    // MARK: - Properties

    private let chatsCollection = Firestore.firestore().collection("chats_refactored")
    var listener: ListenerRegistration?
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.cornellappdev.Resell", category: "FirestoreManager")

    // MARK: - Chat Functions

    func findChatId(listingId: String, buyerId: String, sellerId: String) async throws -> String? {
        let query = chatsCollection
            .whereField(ChatDocument.listingIdKey, isEqualTo: listingId)
            .whereField(ChatDocument.buyerIdKey, isEqualTo: buyerId)
            .whereField(ChatDocument.sellerIdKey, isEqualTo: sellerId)

        let snapshot = try await query.getDocuments()
        return snapshot.documents.first?.documentID
    }

    /// Subscribe to chats where a specific field of the chat document is equal to a specific value
    func subscribeToChatsWhereField(_ field: String, isEqualTo: Any, onSnapshotUpdate: @escaping ([Chat]) -> Void) {
        let query = chatsCollection
            .whereField(field, isEqualTo: isEqualTo)

        // remove the listener if it exists
        listener?.remove()

        // add a new listener
        listener = query.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }

            if let error = error {
                logger.error("Error loading chat previews: \(error.localizedDescription)")
                onSnapshotUpdate([])
                return
            }

            guard let documents = querySnapshot?.documents else {
                logger.log("No documents found.")
                onSnapshotUpdate([])
                return
            }

            guard let user = GoogleAuthManager.shared.user else {
                GoogleAuthManager.shared.logger.error("Error in \(#file) \(#function): User not available.")
                onSnapshotUpdate([])
                return
            }

            var chats: [Chat] = []
            let group = DispatchGroup()

            for document in documents {
                group.enter()

                let chatDocument = try? document.data(as: ChatDocument.self)
                let chatId = document.documentID

                Task {
                    // Fetch messages for this chat
                    let messagesQuery = self.chatsCollection.document(chatId).collection("messages")

                    do {
                        let messagesSnapshot = try await messagesQuery.getDocuments()
                        let messageDocuments = try messagesSnapshot.documents.compactMap({ try $0.data(as: MessageDocument.self) })

                        // Create chat with messages
                        if let chatDocument = chatDocument {
                            let chat = try await chatDocument.toChat(userId: user.firebaseUid, messages: messageDocuments)
                            chats.append(chat)
                        }
                    } catch {
                        self.logger.error("Error fetching messages for chat \(chatId): \(error.localizedDescription)")
                    }

                    group.leave()
                }
            }

            group.notify(queue: .main) {
                let sortedChats = chats.sorted(by: { $0.updatedAt > $1.updatedAt })
                onSnapshotUpdate(sortedChats)
            }
        }
    }

    /// Subscribe to buyer chats
    func subscribeToBuyerChats(onUpdate: @escaping ([Chat]) -> Void) {
        guard let user = GoogleAuthManager.shared.user else {
            GoogleAuthManager.shared.logger.error("Error in \(#file) \(#function): User id not available.")
            onUpdate([])
            return
        }

        subscribeToChatsWhereField(ChatDocument.buyerIdKey, isEqualTo: user.firebaseUid, onSnapshotUpdate: onUpdate)
    }

    /// Subscribe to seller chats
    func subscribeToSellerChats(onUpdate: @escaping ([Chat]) -> Void) {
        guard let user = GoogleAuthManager.shared.user else {
            GoogleAuthManager.shared.logger.error("Error in \(#file) \(#function): User id not available.")
            onUpdate([])
            return
        }

        subscribeToChatsWhereField(ChatDocument.sellerIdKey, isEqualTo: user.firebaseUid, onSnapshotUpdate: onUpdate)
    }

    /// Subscribe to single chat updates by id
    func subscribeToChat(
        _ id: String,
        onSnapshotUpdate: @escaping ([Chat]) -> Void
    ) {
        let chatQuery = chatsCollection
            .document(id)

        let messagesQuery = chatQuery.collection("messages")

        // remove the listener if it exists
        listener?.remove()

        // add a new listener
        listener = messagesQuery.addSnapshotListener { [weak self] messagesSnapshot, error in
            guard let self = self else { return }

            if let error = error {
                logger.error("Error loading chat: \(error.localizedDescription)")
                onSnapshotUpdate([])
                return
            }

            guard let messages = messagesSnapshot else {
                logger.log("No document found.")
                onSnapshotUpdate([])
                return
            }

            do {
                try messages.documents.compactMap({ try $0.data(as: MessageDocument.self) })
            } catch {
                logger.error("Error decoding messages: \(error)")
                onSnapshotUpdate([])
                return
            }

            let messageDocuments = try? messages.documents.compactMap({ try $0.data(as: MessageDocument.self) })

            guard let messageDocuments = messageDocuments, messageDocuments.count > 0 else {
                logger.log("No messages found.")
                onSnapshotUpdate([])
                return
            }


            Task {
                guard let chatDocument = try? await self.chatsCollection.document(id).getDocument(as: ChatDocument.self) else {
                    self.logger.error("Unable to get chat document from collection")
                    onSnapshotUpdate([])
                    return
                }

                guard let userId = GoogleAuthManager.shared.user?.firebaseUid else {
                    self.logger.error("Unable to get user id")
                    onSnapshotUpdate([])
                    return
                }

                let chat = try? await chatDocument.toChat(userId: userId, messages: messageDocuments)

                if let chat { onSnapshotUpdate([chat]) }
            }
        }
    }

    /// Stop listening for updates
    func stopListening() {
        listener?.remove()
    }

}

extension Date {
    func toFormattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }

    static func timeAgo(from timestampString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = formatter.date(from: timestampString) else {
            return "Invalid Date"
        }

        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .full

        let now = Date()
        return relativeFormatter.localizedString(for: date, relativeTo: now)
    }

    static func timeAgo(from datetime: Date) -> String {
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .full

        let now = Date()
        return relativeFormatter.localizedString(for: datetime, relativeTo: now)
    }

    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }

    func adding(minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }
}
