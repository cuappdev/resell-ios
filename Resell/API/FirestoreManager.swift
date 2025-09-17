//
//  FirestoreManager.swift
//  Resell
//
//  Created by Richie Sun on 11/29/24.
//

import FirebaseFirestore
import os

class FirestoreManager {

    // MARK: - Singleton Instance

    static let shared = FirestoreManager()

    // MARK: - Init

    private init() { }

    // MARK: - Properties

    private let chatsCollection = Firestore.firestore().collection("chats_refactored")
    var listeners: [String: ListenerRegistration] = [:]
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
        listeners[field]?.remove()

        // add a new listener
        listeners[field] = query.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }

            if let error = error {
                logger.error("Error loading chat previews: \(error)")
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
//                        let messageDocuments = try messagesSnapshot.documents.compactMap({ try $0.data(as: MessageDocument.self) })
                        let messageDocuments = try messagesSnapshot.documents.compactMap({ doc in
                            return try doc.data(as: MessageDocument.self)
                        })

                        // Create chat with messages
                        if let chatDocument = chatDocument {
                            let chat = try await chatDocument.toChat(userId: user.firebaseUid, messages: messageDocuments)
                            chats.append(chat)
                        }
                    } catch {
                        self.logger.error("Error fetching messages for chat \(chatId): \(error)")
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

        // remove all listeners from the dictionary
        listeners.forEach { _, listener in
            listener.remove()
        }

        listeners = [:]

        // add a new listener
        listeners["chat"] = messagesQuery.addSnapshotListener { [weak self] messagesSnapshot, error in
            guard let self = self else { return }

            if let error = error {
                logger.error("Error loading chat: \(error)")
                onSnapshotUpdate([])
                return
            }

            guard let messages = messagesSnapshot else {
                logger.log("No document found.")
                onSnapshotUpdate([])
                return
            }

            let messageDocuments = messages.documents.compactMap({ doc in
                do {
                    return try doc.data(as: MessageDocument.self)
                } catch {
                    self.logger.error("Error decoding message document: \(error)")
                }

                return nil
            })

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
        listeners.forEach { _, listener in
            listener.remove()
        }
        
        listeners = [:]
    }

    /// Stop listening to the purchase and buyer chats
    func stopListeningAll() {
        listeners[ChatDocument.buyerIdKey]?.remove()
        listeners[ChatDocument.sellerIdKey]?.remove()
        listeners.removeValue(forKey: ChatDocument.buyerIdKey)
        listeners.removeValue(forKey: ChatDocument.sellerIdKey)
    }

    /// Stop listening to a single chat
    func stopListeningToChat() {
        listeners["chat"]?.remove()
        listeners.removeValue(forKey: "chat")
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
