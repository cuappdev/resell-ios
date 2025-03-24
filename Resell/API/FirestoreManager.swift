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

    // MARK: - Properties

    private let chatsCollection = Firestore.firestore().collection("chats")
    private var listener: ListenerRegistration?
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.cornellappdev.Resell", category: "FirestoreManager")

    // MARK: - Chat Functions

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


                Task {
                    let chat = try? await chatDocument?.toChat(userId: user.firebaseUid)
                    if let chat { chats.append(chat) }

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
        // Remove any existing listener
        listener?.remove()

        // Subscribe to the chat document
        subscribeToChatsWhereField(ChatDocument.idKey, isEqualTo: id, onSnapshotUpdate: onSnapshotUpdate)
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
