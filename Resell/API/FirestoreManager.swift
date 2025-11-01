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

    // MARK: - Properties

    private let firestore = Firestore.firestore()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.cornellappdev.Resell", category: "FirestoreManager")

    // MARK: - Init

    private init() {}

    // MARK: - Functions

    func getUserOnboarded(email: String) async throws -> Bool {
        do {
            let document = try await firestore.collection("user").document(email).getDocument()
            let user = try document.data(as: FirebaseDocument.self)
            logger.info("Successfully fetched onboarding status for user \(email).")
            return user.onboarded
        } catch {
            logger.error("Error fetching user onboarding status for user \(email): \(error.localizedDescription)")
            throw error
        }
    }

    func getVenmoHandle(email: String) async throws -> String {
        do {
            let document = try await firestore.collection("user").document(email).getDocument()
            let user = try document.data(as: FirebaseDocument.self)
            logger.info("Successfully fetched Venmo handle for user \(email).")
            return user.venmo
        } catch {
            logger.error("Error fetching Venmo handle for user \(email): \(error.localizedDescription)")
            throw error
        }
    }

    func saveDeviceToken(userEmail: String, deviceToken: String) async throws {
        do {
            try await firestore.collection("user").document(userEmail).updateData(["fcmToken": deviceToken])
            logger.info("Successfully saved device token for user \(userEmail).")
        } catch {
            logger.error("Error saving device token for user \(userEmail): \(error.localizedDescription)")
            throw error
        }
    }

    func saveOnboarded(userEmail: String) async throws {
        do {
            try await firestore.collection("user").document(userEmail).updateData(["onboarded": true])
            logger.info("Successfully saved onboarding status for user \(userEmail).")
        } catch {
            logger.error("Error saving onboarding status for user \(userEmail): \(error.localizedDescription)")
            throw error
        }
    }

    func saveVenmo(userEmail: String, venmo: String) async throws {
        do {
            try await firestore.collection("user").document(userEmail).updateData(["venmo": venmo])
            logger.info("Successfully saved Venmo handle for user \(userEmail).")
        } catch {
            logger.error("Error saving Venmo handle for user \(userEmail): \(error.localizedDescription)")
            throw error
        }
    }

    func saveNotificationsEnabled(userEmail: String, notificationsEnabled: Bool) async throws {
        do {
            try await firestore.collection("user").document(userEmail).updateData(["notificationsEnabled": notificationsEnabled])
            logger.info("Successfully saved notifications enabled status for user \(userEmail).")
        } catch {
            logger.error("Error saving notifications enabled status for user \(userEmail): \(error.localizedDescription)")
            throw error
        }
    }
}
