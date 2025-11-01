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

    @Published var chats: [Chat] = []
    @Published var selectedTab: String = "Purchases"

    init() {
        fetchChats()
    }

    // MARK: - Functions

    func fetchChats() {
        guard let userEmail = UserSessionManager.shared.email else { return }

        FirestoreManager.shared.fetchChats(for: userEmail) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let chats):
                    self?.chats = chats
                case .failure(let error):
                    print("Failed to fetch chats: \(error.localizedDescription)")
                }
            }
        }
    }

    func addChat(_ chat: Chat) {
        guard let userEmail = UserSessionManager.shared.email else { return }

        FirestoreManager.shared.addChat(for: userEmail, chat: chat) { result in
            switch result {
            case .success:
                print("Chat added successfully")
            case .failure(let error):
                print("Failed to add chat: \(error.localizedDescription)")
            }
        }
    }

    func deleteChat(chatId: String) {
        guard let userEmail = UserSessionManager.shared.email else { return }
        
        FirestoreManager.shared.deleteChat(for: userEmail, chatId: chatId) { result in
            switch result {
            case .success:
                print("Chat deleted successfully")
            case .failure(let error):
                print("Failed to delete chat: \(error.localizedDescription)")
            }
        }
    }
}
