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
    
    // Archived chats (completed transactions)
    @Published var archivedChats: [Chat] = []

    @Published var purchaseUnread: Int = 0
    @Published var offerUnread: Int = 0

    @Published var selectedChat: Chat? = nil
    @Published var selectedPost: Post? = nil

    @Published var subscribedChat: [MessageCluster] = []
    @Published var selectedTab: ChatTab = .purchases

    @Published var draftMessageText: String = ""
    @Published var availabilityDates: [Availability] = []

    @Published var otherUserProfileImage: UIImage = UIImage(named: "emptyProfile")!
    
    private var isListening = false
    private var blockedUsers: [String] = []

    var otherUser: User?
    var venmoURL: URL?
    
    // MARK: - Init
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(stopListening),
            name: Constants.Notifications.LogoutUser,
            object: nil
        )
    }

    // MARK: - Functions

    func checkEmptyState() -> Bool {
        switch selectedTab {
        case .purchases:
            return purchaseChats.isEmpty
        case .offers:
            return offerChats.isEmpty
        case .archived:
            return archivedChats.isEmpty
        }
    }

    func emptyStateTitle() -> String {
        switch selectedTab {
        case .purchases:
            return "No messages with sellers yet"
        case .offers:
            return "No messages with buyers yet"
        case .archived:
            return "No archived messages"
        }
    }

    func emptyStateMessage() -> String {
        switch selectedTab {
        case .purchases:
            return "When you contact a seller, you'll see your messages here"
        case .offers:
            return "When a buyer contacts you, you'll see their messages here"
        case .archived:
            return "Completed transactions will appear here"
        }
    }

    func getAllChats() {
        guard !isListening else { return }
        // The Firestore subscriptions read `GoogleAuthManager.shared.user` to
        // build the buyer/seller queries. If we set `isListening = true` while
        // the user is still nil (e.g. when MainTabView's logged-in branch
        // mounts a tick before `restoreSignIn` finishes populating the user)
        // the subscriptions never attach, and every later caller is short-
        // circuited by the guard above. Bail out instead so callers like
        // `ChatsView.onAppear` or the `userDidLogin` `.onChange` can retry
        // once the user is actually loaded.
        guard GoogleAuthManager.shared.user != nil else { return }
        isListening = true
        
        getPurchaceChats()
        getOfferChats()
    }
    
    func refreshChats() {
        stopListening()
        getAllChats()
    }
    
    @objc func stopListening() {
        FirestoreManager.shared.stopListeningAll()
        isListening = false
        purchaseChats = []
        offerChats = []
        purchaseUnread = 0
        offerUnread = 0
    }

    func getPurchaceChats() {
        isLoading = true
        FirestoreManager.shared.subscribeToBuyerChats { [weak self] purchaseChats in
            guard let self else { return }

            let filteredChats = purchaseChats.filter { !self.blockedUsers.contains($0.other.email) }
            
            // Separate active and archived (sold) chats
            self.purchaseChats = filteredChats.filter { $0.post.sold != true }
            let archivedPurchases = filteredChats.filter { $0.post.sold == true }
            
            // Merge with existing archived chats from offers
            self.updateArchivedChats(purchases: archivedPurchases)
            
            self.purchaseUnread = self.countUnviewedChats(chats: self.purchaseChats)
            isLoading = false
        }
    }

    func getOfferChats() {
        isLoading = true
        FirestoreManager.shared.subscribeToSellerChats { [weak self] offerChats in
            guard let self else { return }

            let filteredChats = offerChats.filter { !self.blockedUsers.contains($0.other.email) }
            
            // Separate active and archived (sold) chats
            self.offerChats = filteredChats.filter { $0.post.sold != true }
            let archivedOffers = filteredChats.filter { $0.post.sold == true }
            
            // Merge with existing archived chats from purchases
            self.updateArchivedChats(offers: archivedOffers)
            
            self.offerUnread = self.countUnviewedChats(chats: self.offerChats)
            isLoading = false
        }
    }
    
    private var archivedPurchasesCache: [Chat] = []
    private var archivedOffersCache: [Chat] = []
    
    private func updateArchivedChats(purchases: [Chat]? = nil, offers: [Chat]? = nil) {
        if let purchases = purchases {
            archivedPurchasesCache = purchases
        }
        if let offers = offers {
            archivedOffersCache = offers
        }
        
        // Combine and sort by updatedAt
        archivedChats = (archivedPurchasesCache + archivedOffersCache)
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func countUnviewedChats(chats: [Chat]) -> Int {
        return chats.reduce(into: 0) { $0 += ($1.messages.filter { !$0.read && !$0.mine }.count) }
    }

    /// Total unread messages across both purchase and offer chats. Used to drive
    /// the unread badge on the messages tab in the bottom tab bar.
    var totalUnread: Int {
        purchaseUnread + offerUnread
    }

    /// Optimistically mark every "their" message in the given chat as read in our
    /// local cache and recompute unread counts.
    ///
    /// The Firestore listener in `subscribeToChatsWhereField` only re-fires when
    /// the parent chat document changes, not when documents in the `messages`
    /// subcollection are mutated. As a result, the network mark-as-read calls
    /// triggered from `MessagesViewModel.subscribeToChat` would not propagate
    /// back to the chat list until the user pulled to refresh. This method lets
    /// the chat list reflect "I've opened and read this conversation" instantly,
    /// staying consistent with the actual mark-as-read network calls fired from
    /// the messages view.
    func markChatAsLocallyRead(chatId: String) {
        purchaseChats = purchaseChats.map { markRead(chat: $0, ifMatching: chatId) }
        offerChats = offerChats.map { markRead(chat: $0, ifMatching: chatId) }
        purchaseUnread = countUnviewedChats(chats: purchaseChats)
        offerUnread = countUnviewedChats(chats: offerChats)
    }

    private func markRead(chat: Chat, ifMatching chatId: String) -> Chat {
        guard chat.id == chatId else { return chat }
        let updatedMessages: [any Message] = chat.messages.map { msg in
            guard !msg.mine, !msg.read else { return msg }
            var copy = msg
            copy.read = true
            return copy
        }
        return Chat(
            id: chat.id,
            post: chat.post,
            other: chat.other,
            lastMessage: chat.lastMessage,
            updatedAt: chat.updatedAt,
            messages: updatedMessages
        )
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
    case archived = "Archived"
}
