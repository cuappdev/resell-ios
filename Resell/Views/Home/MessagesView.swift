//
//  MessagesView.swift
//  Resell
//
//  Created by Richie Sun on 10/26/24.
//

import SwiftUI

// MARK: - MessageView
struct MessagesView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router

    //TODO: Change back to Env Object
    @StateObject var viewModel = ChatsViewModel()

    // MARK: - UI

    var body: some View {
        VStack {
            messageContentView

            Divider()

            MessageInputView(messageText: $viewModel.messageText) {
                viewModel.sendMessage()
            }

        }



    }

    private var messageContentView: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                VStack {
                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(message: message)
                    }
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastMessage = viewModel.messages.last?.id {
                        scrollViewProxy.scrollTo(lastMessage, anchor: .bottom)
                    }
                }
            }
            .background(Constants.Colors.white)
            .onAppear {
                viewModel.fetchMessages()
            }
        }
    }
}

// MARK: - MessageBubbleView
struct MessageBubbleView: View {
    let message: Message

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if message.isSentByCurrentUser {
                Spacer()
            }

            if !message.isSentByCurrentUser {
                AsyncImage(url: URL(string: message.user.avatar)) { image in
                    image.resizable()
                } placeholder: {
                    Circle().fill(Color.gray)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            }

            VStack(alignment: message.isSentByCurrentUser ? .trailing : .leading) {
                Text(message.text)
                    .padding()
                    .background(message.isSentByCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(message.isSentByCurrentUser ? .white : .black)
                    .cornerRadius(15)

                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            if !message.isSentByCurrentUser {
                Spacer()
            }
        }
        .padding(message.isSentByCurrentUser ? .leading : .trailing, 60)
        .padding(.vertical, 5)
    }
}

// MARK: - MessageInputView
struct MessageInputView: View {
    @Binding var messageText: String
    var onSend: () -> Void

    var body: some View {
        HStack {
            TextField("Message...", text: $messageText)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 24))
                    .padding(8)
            }
        }
        .padding()
    }
}


