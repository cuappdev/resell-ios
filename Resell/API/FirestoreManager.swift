//
//  FirestoreManager.swift
//  Resell
//
//  Created by Richie Sun on 11/29/24.
//

import Foundation
import FirebaseFirestore
import os
import SwiftUI

class FirestoreManager {

    // MARK: - Singleton Instance

    static let shared = FirestoreManager()
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.cornellappdev.Resell", category: "FirestoreManager")

    // MARK: - Properties

    private let firestore = Firestore.firestore()

    private let historyCollection = Firestore.firestore().collection("history")
    private let chatsCollection = Firestore.firestore().collection("chats")

    private var listener: ListenerRegistration?

    // MARK: - User Functions

    // Check if a user is onboarded
    func getUserOnboarded(email: String) async throws -> Bool {
        do {
            let document = try await firestore.collection("user").document(email).getDocument()
            let user = try document.data(as: FirebaseDocument.self)
            return user.onboarded
        } catch {
            logger.error("Error fetching onboarding status for \(email): \(error.localizedDescription)")
            throw error
        }
    }

    // Fetch Venmo handle
    func getVenmoHandle(email: String) async throws -> String {
        do {
            let document = try await firestore.collection("user").document(email).getDocument()
            let user = try document.data(as: FirebaseDocument.self)
            return user.venmo
        } catch {
            logger.error("Error fetching Venmo handle for \(email): \(error.localizedDescription)")
            throw error
        }
    }

    // Fetch FCM Token
    func getUserFCMToken(email: String) async throws -> String? {
        do {
            let document = try await firestore.collection("user").document(email).getDocument()
            let user = try document.data(as: FirebaseDocument.self)
            return user.fcmToken
        } catch {
            logger.error("Error fetching FCM token for \(email): \(error.localizedDescription)")
            throw error
        }
    }

    // Fetch Notifications Enabled Status
    func getNotificationsEnabled(email: String) async throws -> Bool {
        do {
            let document = try await firestore.collection("user").document(email).getDocument()
            let user = try document.data(as: FirebaseDocument.self)
            return user.notificationsEnabled
        } catch {
            logger.error("Error fetching notifications status for \(email): \(error.localizedDescription)")
            throw error
        }
    }

    // Save Device Token
    func saveDeviceToken(userEmail: String, deviceToken: String) async throws {
        do {
            try await firestore.collection("user").document(userEmail).updateData(["fcmToken": deviceToken])
        } catch {
            logger.error("Error saving device token for \(userEmail): \(error.localizedDescription)")
            throw error
        }
    }

    // Save Onboarding Status
    func saveOnboarded(userEmail: String) async throws {
        do {
            try await firestore.collection("user").document(userEmail).updateData(["onboarded": true])
        } catch {
            logger.error("Error saving onboarding status for \(userEmail): \(error.localizedDescription)")
            throw error
        }
    }

    // Save Venmo Handle
    func saveVenmo(userEmail: String, venmo: String) async throws {
        do {
            try await firestore.collection("user").document(userEmail).updateData(["venmo": venmo])
        } catch {
            logger.error("Error saving Venmo handle for \(userEmail): \(error.localizedDescription)")
            throw error
        }
    }

    // Save Notifications Enabled
    func saveNotificationsEnabled(userEmail: String, notificationsEnabled: Bool) async throws {
        do {
            try await firestore.collection("user").document(userEmail).updateData(["notificationsEnabled": notificationsEnabled])
        } catch {
            logger.error("Error saving notifications enabled status for \(userEmail): \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Chat Functions

    func getPurchaseChats(completion: @escaping ([ChatPreview]) -> Void) {
        guard let userEmail = UserSessionManager.shared.email else {
            UserSessionManager.shared.logger.error("Error in ChatsViewModel: User email not available.")
            completion([])
            return
        }

        let sellersQuery = historyCollection
            .document(userEmail)
            .collection("sellers")

        listener = sellersQuery.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }

            if let error = error {
                logger.error("Error loading chat previews: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let documents = querySnapshot?.documents else {
                logger.log("No documents found.")
                completion([])
                return
            }

            var tempPurchases: [ChatPreview] = []

            let group = DispatchGroup()

            for document in documents {
                group.enter()

                let data = document.data()
                let sellerId = document.documentID

                guard let sellerName = data["name"] as? String,
                      let image = data["image"] as? String,
                      let recentMessage = data["recentMessage"] as? String,
                      let recentSender = data["recentSender"] as? String,
                      let recentMessageTime = data["recentMessageTime"] as? String,
                      let viewed = data["viewed"] as? Bool,
                      let confirmedTime = data["confirmedTime"] as? String else {
                    group.leave()
                    continue
                }

                let sellerHistoryRef = historyCollection
                    .document(sellerId)
                    .collection("buyers")
                    .document(userEmail)

                let itemsCollection = sellerHistoryRef.collection("items")

                itemsCollection.getDocuments { snapshot, error in
                    if let error = error {
                        self.logger.error("Error fetching items: \(error.localizedDescription)")
                        group.leave()
                        return
                    }

                    let items = snapshot?.documents.compactMap { $0.data() } ?? []

                    let chatPreview = ChatPreview(
                        sellerName: sellerName,
                        email: sellerId,
                        recentItem: data["item"] as? [String: Any] ?? [:],
                        image: URL(string: image),
                        recentMessage: recentMessage,
                        recentSender: recentSender == userEmail ? 1 : 0,
                        viewed: viewed,
                        confirmedTime: confirmedTime,
                        proposedTime: data["proposedTime"] as? String,
                        proposedViewed: data["proposedViewed"] as? Bool ?? false,
                        recentMessageTime: recentMessageTime,
                        proposer: data["proposer"] as? String,
                        items: items
                    )

                    tempPurchases.append(chatPreview)
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                let sortedPurchases = tempPurchases.sorted(by: { $0.recentMessageTime > $1.recentMessageTime })
                completion(sortedPurchases)
            }
        }
    }

    func getOfferChats(completion: @escaping ([ChatPreview]) -> Void) {
        guard let userEmail = UserSessionManager.shared.email else {
            UserSessionManager.shared.logger.error("Error in ChatsViewModel: User email not available.")
            completion([])
            return
        }

        let buyersQuery = historyCollection
            .document(userEmail)
            .collection("buyers")

        listener = buyersQuery.addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self else { return }

            if let error = error {
                logger.error("Error loading chat previews: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let documents = querySnapshot?.documents else {
                logger.log("No documents found.")
                completion([])
                return
            }

            var tempOffers: [ChatPreview] = []

            let group = DispatchGroup()

            for document in documents {
                group.enter()

                let data = document.data()
                let buyerId = document.documentID

                guard let buyerName = data["name"] as? String,
                      let image = data["image"] as? String,
                      let recentMessage = data["recentMessage"] as? String,
                      let recentSender = data["recentSender"] as? String,
                      let recentMessageTime = data["recentMessageTime"] as? String,
                      let viewed = data["viewed"] as? Bool,
                      let confirmedTime = data["confirmedTime"] as? String else {
                    group.leave()
                    continue
                }

                let buyerHistoryRef = historyCollection
                    .document(buyerId)
                    .collection("sellers")
                    .document(userEmail)

                let itemsCollection = buyerHistoryRef.collection("items")

                itemsCollection.getDocuments { snapshot, error in
                    if let error = error {
                        self.logger.error("Error fetching items: \(error.localizedDescription)")
                        group.leave()
                        return
                    }

                    let items = snapshot?.documents.compactMap { $0.data() } ?? []

                    let chatPreview = ChatPreview(
                        sellerName: buyerName,
                        email: buyerId,
                        recentItem: data["item"] as? [String: Any] ?? [:],
                        image: URL(string: image),
                        recentMessage: recentMessage,
                        recentSender: recentSender == userEmail ? 1 : 0,
                        viewed: viewed,
                        confirmedTime: confirmedTime,
                        proposedTime: data["proposedTime"] as? String,
                        proposedViewed: data["proposedViewed"] as? Bool ?? false,
                        recentMessageTime: recentMessageTime,
                        proposer: data["proposer"] as? String,
                        items: items
                    )

                    tempOffers.append(chatPreview)
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                let sortedOffers = tempOffers.sorted(by: { $0.recentMessageTime > $1.recentMessageTime })
                completion(sortedOffers)
            }
        }
    }

    func getSpecificChat(buyer: String, seller: String, completion: @escaping ([ChatPreview]) -> Void) {
        guard let userEmail = UserSessionManager.shared.email else {
            UserSessionManager.shared.logger.error("Error in ChatsViewModel: User email not available.")
            completion([])
            return
        }
    }

    func updateChatViewedStatus(chatType: String, userEmail: String, chatId: String, isViewed: Bool) {
        let collectionType = chatType == "Purchases" ? "sellers" : "buyers"
        let chatDocument = historyCollection.document(userEmail).collection(collectionType).document(chatId)

        chatDocument.updateData(["viewed": isViewed]) { error in
            if let error = error {
                FirestoreManager.shared.logger.error("Error updating chat viewed status: \(error.localizedDescription)")
            } else {
                FirestoreManager.shared.logger.log("Successfully updated chat viewed status for chat \(chatId).")
            }
        }
    }


    /// Stop listening for updates
    func stopListening() {
        listener?.remove()
    }

    // Fetch Buyer History
    func getBuyerHistory(email: String) async throws -> [TransactionSummary] {
        do {
            let documents = try await historyCollection.document(email).collection("buyers").getDocuments()
            return documents.documents.compactMap { try? $0.data(as: TransactionSummary.self) }
        } catch {
            logger.error("Error fetching buyer history for \(email): \(error.localizedDescription)")
            throw error
        }
    }

    // Fetch Seller History
    func getSellerHistory(email: String) async throws -> [TransactionSummary] {
        do {
            let documents = try await historyCollection.document(email).collection("sellers").getDocuments()
            return documents.documents.compactMap { try? $0.data(as: TransactionSummary.self) }
        } catch {
            logger.error("Error fetching seller history for \(email): \(error.localizedDescription)")
            throw error
        }
    }

    // Subscribe to Chat Updates
    func subscribeToChat(
        buyerEmail: String,
        sellerEmail: String,
        onSnapshotUpdate: @escaping ([ChatDocument]) -> Void
    ) {
        // Remove any existing listener
        listener?.remove()
        
        // Reference Firestore collection
        let chatDocRef = firestore.collection("chats")
            .document(buyerEmail)
            .collection(sellerEmail)
            .order(by: "createdAt", descending: false)

        // Add snapshot listener
        listener = chatDocRef.addSnapshotListener { snapshot, error in
            if let error = error {
                // Log Firestore error
                self.logger.error("Firestore subscription error: \(error.localizedDescription)")
                return
            }

            // Ensure snapshot exists
            guard let snapshot = snapshot else {
                self.logger.error("Firestore subscription returned no data.")
                return
            }

            // Parse snapshot documents manually
            var messages: [ChatDocument] = snapshot.documents.compactMap { document in
                let data = document.data()

                // Parse user
                let userMap = data["user"] as? [String: Any]
                let user = userMap.flatMap {
                    UserDocument(
                        _id: $0["_id"] as? String ?? "",
                        avatar: $0["avatar"] as? URL,
                        name: $0["name"] as? String ?? ""
                    )
                }

                // Parse product
                let productMap = data["product"] as? [String: Any]
                let product = productMap.flatMap {
                    Post(
                        id: $0["id"] as? String ?? "",
                        title: $0["title"] as? String ?? "",
                        description: $0["description"] as? String ?? "",
                        categories: $0["categories"] as? [String] ?? [],
                        originalPrice: $0["price"] as? String ?? "",

                        alteredPrice: $0["altered_price"] as? String ?? "",
                        images: $0["images"] as? [URL] ?? [],
                        created: $0["created"] as? String ?? "",
                        location: $0["location"] as? String ?? "",
                        archive: ($0["archive"] as? Bool) ?? false,
                        user: nil
                    )
                }

                // Parse availability
                let availabilityArray = data["availability"] as? [[String: Any]]
                let availability = availabilityArray.flatMap { array in
                    AvailabilityDocument(availabilities: array.compactMap { availabilityItem in
                        guard let startDate = availabilityItem["startDate"] as? Timestamp,
                              let id = availabilityItem["id"] as? Int,
                              let color = availabilityItem["color"] as? String else {
                            return nil
                        }
                        return AvailabilityBlock(startDate: startDate, color: color, id: id)
                    })
                }

                // Parse meeting info
                let meetingInfoMap = data["meetingInfo"] as? [String: Any]
                let meetingInfo = meetingInfoMap.flatMap {
                    MeetingInfo(
                        state: $0["state"] as? String ?? "",
                        proposeTime: $0["proposeTime"] as? String ?? "",
                        proposer: $0["proposer"] as? String,
                        canceler: $0["canceler"] as? String,
                        mostRecent: $0["mostRecent"] as? Bool ?? false
                    )
                }

                // Create ChatDocument manually
                return ChatDocument(
                    _id: data["_id"] as? String ?? "",
                    createdAt: data["createdAt"] as? Timestamp ?? Timestamp(seconds: 0, nanoseconds: 0),
                    user: user ?? UserDocument(_id: "", avatar: nil, name: ""),
                    availability: availability,
                    product: product,
                    image: data["image"] as? String ?? "",
                    text: data["text"] as? String ?? "",
                    meetingInfo: meetingInfo
                )
            }

            messages = messages.sorted { $0.createdAt.dateValue() < $1.createdAt.dateValue() }

            // Pass messages to the callback
            onSnapshotUpdate(messages)
        }
    }

    // Send Text Message
    func sendChatMessage(
        buyerEmail: String,
        sellerEmail: String,
        chatDocument: ChatDocumentSendable
    ) async throws {
        let chatRef = firestore.collection("chats")
            .document(buyerEmail)
            .collection(sellerEmail)
        var data = try chatDocument.toFirebaseDictionary()

        data["createdAt"] = Timestamp()
        try await chatRef.addDocument(data: data)
    }

    // Send Product Message
    func sendProductMessage(
        buyerEmail: String,
        sellerEmail: String,
        otherDocument: ChatDocument,
        post: Post
    ) async throws {
        var chatDocument = otherDocument
        chatDocument._id = "\(Date().timeIntervalSince1970)"
        chatDocument.createdAt = Timestamp(date: Date())
        chatDocument.image = ""
        chatDocument.text = ""
        chatDocument.availability = nil
        chatDocument.product = post
        
        let chatRef = firestore.collection("chats")
            .document(buyerEmail)
            .collection(sellerEmail)

        let data = try chatDocument.toFirebaseDictionary()
        try await chatRef.addDocument(data: data)
    }

    // Update Buyer History
    func updateBuyerHistory(
        sellerEmail: String,
        buyerEmail: String,
        data: TransactionSummary
    ) async throws {
        let docRef = firestore.collection("history")
            .document(sellerEmail)
            .collection("buyers")
            .document(buyerEmail)

        try docRef.setData(from: data)
    }

    // Update Seller History
    func updateSellerHistory(
        buyerEmail: String,
        sellerEmail: String,
        data: TransactionSummary
    ) async throws {
        let docRef = firestore.collection("history")
            .document(buyerEmail)
            .collection("sellers")
            .document(sellerEmail)

        try docRef.setData(from: data)
    }

    // Update Items
    func updateItems(
        email: String,
        postId: String,
        post: Post
    ) async throws {
        let docRef = firestore.collection("history")
            .document(email)
            .collection("items")
            .document(postId)

        try docRef.setData(from: post)
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

    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }

    func adding(minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }
}

extension Encodable {
    /// Converts an Encodable object to a [String: Any] dictionary,
    /// preserving `Timestamp` objects as-is.
    func toFirebaseDictionary() throws -> [String: Any] {
        // Create a custom encoder
        let encoder = JSONEncoder()

        // Use `JSONSerialization` with Foundation objects to preserve `Timestamp`
        let data = try encoder.encode(self)
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])

        // Ensure the result is a dictionary
        guard var dictionary = jsonObject as? [String: Any] else {
            throw NSError(domain: "toFirebaseDictionary", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert object to dictionary"])
        }

        // Manually check for and preserve any `Timestamp` properties
        for (key, value) in dictionary {
            if let timestampValue = value as? Timestamp {
                dictionary[key] = timestampValue // Preserve as `Timestamp`
                print(timestampValue)
            }
        }

        return dictionary
    }
}

