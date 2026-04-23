//
//  FirestoreManager.swift
//  Resell
//
//  Created by Richie Sun on 11/29/24.
//

import FirebaseFirestore
import Foundation
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

    /// Ensures overlapping async rebuilds from rapid snapshots cannot deliver stale UI:
    /// only the latest snapshot per list query (or per single-chat stream) may call `onSnapshotUpdate`.
    private let snapshotEpochLock = NSLock()
    private var chatListSnapshotEpoch: [String: UInt64] = [:]
    private var detailChatSnapshotEpoch: UInt64 = 0

    private func bumpChatListSnapshotEpoch(for field: String) -> UInt64 {
        snapshotEpochLock.lock()
        defer { snapshotEpochLock.unlock() }
        let next = (chatListSnapshotEpoch[field] ?? 0) &+ 1
        chatListSnapshotEpoch[field] = next
        return next
    }

    private func chatListSnapshotEpochStillCurrent(field: String, epoch: UInt64) -> Bool {
        snapshotEpochLock.lock()
        defer { snapshotEpochLock.unlock() }
        return chatListSnapshotEpoch[field] == epoch
    }

    private func bumpDetailChatSnapshotEpoch() -> UInt64 {
        snapshotEpochLock.lock()
        defer { snapshotEpochLock.unlock() }
        detailChatSnapshotEpoch &+= 1
        return detailChatSnapshotEpoch
    }

    private func detailChatSnapshotEpochStillCurrent(_ epoch: UInt64) -> Bool {
        snapshotEpochLock.lock()
        defer { snapshotEpochLock.unlock() }
        return detailChatSnapshotEpoch == epoch
    }

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
                _ = self.bumpChatListSnapshotEpoch(for: field)
                onSnapshotUpdate([])
                return
            }

            guard let documents = querySnapshot?.documents else {
                logger.log("No documents found.")
                _ = self.bumpChatListSnapshotEpoch(for: field)
                onSnapshotUpdate([])
                return
            }

            guard let user = GoogleAuthManager.shared.user else {
                GoogleAuthManager.shared.logger.error("Error in \(#file) \(#function): User not available.")
                _ = self.bumpChatListSnapshotEpoch(for: field)
                onSnapshotUpdate([])
                return
            }

            // Snapshot what we need from the documents synchronously so we don't
            // capture Firestore document handles across the concurrent boundary.
            let chatDocuments: [(id: String, document: ChatDocument)] = documents.compactMap { doc in
                guard let parsed = try? doc.data(as: ChatDocument.self) else {
                    self.logger.error("Failed to decode ChatDocument \(doc.documentID)")
                    return nil
                }
                return (doc.documentID, parsed)
            }

            let epoch = self.bumpChatListSnapshotEpoch(for: field)

            Task {
                // Make sure subsequent lookups for the current user are cache hits.
                await ChatProfileCache.shared.setUser(user)

                let chats = await withTaskGroup(of: Chat?.self, returning: [Chat].self) { group in
                    for (chatId, chatDocument) in chatDocuments {
                        group.addTask {
                            await self.buildChat(chatId: chatId, chatDocument: chatDocument, currentUser: user)
                        }
                    }

                    var collected: [Chat] = []
                    for await chat in group {
                        if let chat { collected.append(chat) }
                    }
                    return collected
                }

                guard self.chatListSnapshotEpochStillCurrent(field: field, epoch: epoch) else { return }

                let sortedChats = chats.sorted(by: { $0.updatedAt > $1.updatedAt })
                await MainActor.run { onSnapshotUpdate(sortedChats) }
            }
        }
    }

    /// Resolve post/buyer/seller in parallel (skipping the network for the current user)
    /// and assemble a Chat. Returns nil if the chat can't be built (e.g. missing post).
    private func buildChat(chatId: String, chatDocument: ChatDocument, currentUser: User) async -> Chat? {
        do {
            let messagesQuery = chatsCollection.document(chatId).collection("messages")

            async let messagesTask: [MessageDocument] = {
                let snapshot = try await messagesQuery.getDocuments()
                return snapshot.documents.compactMap { doc in
                    do {
                        return try doc.data(as: MessageDocument.self)
                    } catch {
                        self.logger.error("Error decoding message in chat \(chatId): \(error.localizedDescription)")
                        return nil
                    }
                }
            }()

            async let postTask = ChatProfileCache.shared.post(id: chatDocument.listingID)
            async let buyerTask: User = (chatDocument.buyerID == currentUser.firebaseUid)
                ? currentUser
                : ChatProfileCache.shared.user(id: chatDocument.buyerID)
            async let sellerTask: User = (chatDocument.sellerID == currentUser.firebaseUid)
                ? currentUser
                : ChatProfileCache.shared.user(id: chatDocument.sellerID)

            let (post, buyer, seller, messages) = try await (postTask, buyerTask, sellerTask, messagesTask)

            guard let post else {
                logger.error("Skipping chat \(chatId): post \(chatDocument.listingID) not available")
                return nil
            }

            return chatDocument.toChat(
                currentUserId: currentUser.firebaseUid,
                post: post,
                buyer: buyer,
                seller: seller,
                messages: messages
            )
        } catch {
            logger.error("Error building chat \(chatId): \(error.localizedDescription)")
            return nil
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

        _ = bumpDetailChatSnapshotEpoch()

        // add a new listener
        listeners["chat"] = messagesQuery.addSnapshotListener { [weak self] messagesSnapshot, error in
            guard let self = self else { return }

            if let error = error {
                logger.error("Error loading chat: \(error)")
                _ = self.bumpDetailChatSnapshotEpoch()
                onSnapshotUpdate([])
                return
            }

            guard let messages = messagesSnapshot else {
                logger.log("No document found.")
                _ = self.bumpDetailChatSnapshotEpoch()
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

            let epoch = self.bumpDetailChatSnapshotEpoch()

            Task {
                guard let chatDocument = try? await self.chatsCollection.document(id).getDocument(as: ChatDocument.self) else {
                    self.logger.error("Unable to get chat document from collection")
                    if self.detailChatSnapshotEpochStillCurrent(epoch) {
                        onSnapshotUpdate([])
                    }
                    return
                }

                guard let currentUser = GoogleAuthManager.shared.user else {
                    self.logger.error("Unable to get current user")
                    if self.detailChatSnapshotEpochStillCurrent(epoch) {
                        onSnapshotUpdate([])
                    }
                    return
                }

                await ChatProfileCache.shared.setUser(currentUser)

                do {
                    async let postTask = ChatProfileCache.shared.post(id: chatDocument.listingID)
                    async let buyerTask: User = (chatDocument.buyerID == currentUser.firebaseUid)
                        ? currentUser
                        : ChatProfileCache.shared.user(id: chatDocument.buyerID)
                    async let sellerTask: User = (chatDocument.sellerID == currentUser.firebaseUid)
                        ? currentUser
                        : ChatProfileCache.shared.user(id: chatDocument.sellerID)

                    let (post, buyer, seller) = try await (postTask, buyerTask, sellerTask)

                    guard let post else {
                        self.logger.error("Skipping chat \(id): post \(chatDocument.listingID) not available")
                        return
                    }

                    let chat = chatDocument.toChat(
                        currentUserId: currentUser.firebaseUid,
                        post: post,
                        buyer: buyer,
                        seller: seller,
                        messages: messageDocuments
                    )

                    guard self.detailChatSnapshotEpochStillCurrent(epoch) else { return }

                    await MainActor.run { onSnapshotUpdate([chat]) }
                } catch {
                    self.logger.error("Error building chat \(id): \(error.localizedDescription)")
                }
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
