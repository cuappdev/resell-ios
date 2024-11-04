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

    @Published var selectedTab: String = "Purchases"
    @Published var unreadMessages: [String : Int] = ["Purchaes": 1, "Offers": 1]

    // TODO: Replace with Backend Model
    @Published var chats = [
        (0, "DJBustin", "justin", "Speakers", "Message preview", true),
        (1, "DJBustin", "justin", "Speakers", "Message preview", true),
        (2, "DJBustin", "justin", "Speakers", "Message preview", false),
        (3, "DJBustin", "justin", "Speakers", "Message preview", false),
        (4, "DJBustin", "justin", "Speakers", "Message preview", false)
    ]

    @Published var messages: [Message] = []
    @Published var messageText: String = ""

//    private let db = Firestore.firestore()
    private let chatId = "rs929@cornell.edu" // TODO: Update with actual user

    // MARK: - Functions

    func fetchMessages() {
//        db.collection("chats")
//            .document(chatId)
//            .collection("messages")
//            .order(by: "createdAt", descending: false)
//            .addSnapshotListener { snapshot, error in
//                guard let documents = snapshot?.documents else {
//                    print("No documents or error: \(String(describing: error))")
//                    return
//                }
//
//                self.messages = documents.compactMap { document -> Message? in
//                    try? document.data(as: Message.self)
//                }
//            }
    }

    func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let newMessage = Message(
            id: UUID().uuidString,
            text: messageText,
            createdAt: Date(),
            user: FirebaseUser(id: "id", avatar: "justin", name: "Justin Guo"), isSentByCurrentUser: true
        )

        messages.append(newMessage)

        // TODO: - Store to Firebase document

        messageText = ""
    }

}

