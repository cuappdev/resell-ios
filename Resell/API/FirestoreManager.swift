//
//  FirestoreManager.swift
//  Resell
//
//  Created by Richie Sun on 11/29/24.
//

import Foundation
import FirebaseFirestore
import os

class FirestoreManager {

    // MARK: - Singleton Instance

    static let shared = FirestoreManager()
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.cornellappdev.Resell", category: "FirestoreManager")

    // MARK: - Properties

    private let firestore = Firestore.firestore()

    private let historyCollection = Firestore.firestore().collection("history")
    private let chatsCollection = Firestore.firestore().collection("chats")

    private var lastSubscription: ListenerRegistration?

    // MARK: - Functions

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
        lastSubscription?.remove()
        let chatDocRef = chatsCollection.document(buyerEmail).collection(sellerEmail).order(by: "createdAt", descending: false)

        lastSubscription = chatDocRef.addSnapshotListener { snapshot, error in
            if let error = error {
                self.logger.error("Error in snapshot listener: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                self.logger.error("Snapshot listener received no documents.")
                return
            }

            let chatDocuments = documents.compactMap { try? $0.data(as: ChatDocument.self) }
            onSnapshotUpdate(chatDocuments)
        }
    }

    // Send Text Message
    func sendTextMessage(
        buyerEmail: String,
        sellerEmail: String,
        chatDocument: ChatDocument
    ) async throws {
        do {
            let chatRef = chatsCollection.document(buyerEmail).collection(sellerEmail)
            try chatRef.addDocument(from: chatDocument)
        } catch {
            logger.error("Error sending text message: \(error.localizedDescription)")
            throw error
        }
    }
}
