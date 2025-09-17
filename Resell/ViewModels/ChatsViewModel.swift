//
//  ChatsViewModel.swift
//  Resell
//
//  Created by Richie Sun on 10/26/24.
//

import FirebaseFirestore
import SwiftUI
import os

@MainActor
class ChatsViewModel: ObservableObject {

    // MARK: - Properties

    @EnvironmentObject private var mainViewModel: MainViewModel

    @Published var isLoading = false

    @Published var purchaseChats: [Chat] = []
    @Published var offerChats: [Chat] = []

    @Published var purchaseUnread: Int = 0
    @Published var offerUnread: Int = 0

    @Published var selectedChat: Chat? = nil
    @Published var selectedPost: Post? = nil

    @Published var subscribedChat: [MessageCluster] = []
    @Published var selectedTab: ChatTab = .purchases

    @Published var draftMessageText: String = ""
    @Published var availabilityDates: [Availability] = []

    @Published var otherUserProfileImage: UIImage = UIImage(named: "emptyProfile")!

    private var blockedUsers: [String] = []

    var otherUser: User?
    var venmoURL: URL?

    // MARK: - Functions

    func checkEmptyState() -> Bool {
        switch selectedTab {
        case .purchases:
            return purchaseChats.isEmpty
        case .offers:
            return offerChats.isEmpty
        }
    }

    func emptyStateTitle() -> String {
        switch selectedTab {
        case .purchases:
            return "No messages with sellers yet"
        case .offers:
            return "No messages with buyers yet"
        }
    }

    func emptyStateMessage() -> String {
        switch selectedTab {
        case .purchases:
            return "When you contact a seller, you’ll see your messages here"
        case .offers:
            return "When a buyer contacts you, you’ll see their messages here"
        }
    }

    func getAllChats() {
        getPurchaceChats()
        getOfferChats()
    }

    func getPurchaceChats() {
        isLoading = true
        FirestoreManager.shared.subscribeToBuyerChats { [weak self] purchaseChats in
            guard let self else { return }

            self.purchaseChats = purchaseChats.filter { !self.blockedUsers.contains($0.other.email) }
            purchaseUnread = countUnviewedChats(chats: self.purchaseChats)
            isLoading = false
        }
    }

    func getOfferChats() {
        isLoading = true
        FirestoreManager.shared.subscribeToSellerChats { [weak self] offerChats in
            guard let self else { return }

            self.offerChats = offerChats.filter { !self.blockedUsers.contains($0.other.email) }
            offerUnread = countUnviewedChats(chats: self.offerChats)
            isLoading = false
        }
    }

    func countUnviewedChats(chats: [Chat]) -> Int {
        return chats.reduce(into: 0) { $0 += ($1.messages.filter { !$0.read && !$0.mine }.count) }
    }

    func getSelectedChatPost(completion: @escaping (Post) -> Void) {
        if let postId = selectedChat?.post.id {
            isLoading = true

            Task {
                defer { Task { @MainActor in withAnimation { isLoading = false } } }

                do {
                    let postResponse = try await NetworkManager.shared.getPostByID(id: postId)
                    selectedPost = postResponse.post

                    guard let post = postResponse.post else {
                        // TODO: Better error handling
                        NetworkManager.shared.logger.error("Error in \(#file) \(#function): Post not available.")
                        return
                    }

                    completion(post)
                    isLoading = false
                } catch {
                    NetworkManager.shared.logger.error("Error in \(#file) \(#function): \(error)")
                    // TODO: Better error handling
                }
            }
        }
    }

}

enum ChatTab: String, CaseIterable {
    case purchases = "Purchases"
    case offers = "Offers"
}
