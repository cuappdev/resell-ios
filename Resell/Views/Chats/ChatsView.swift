//
//  ChatsView.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import Kingfisher
import SwiftUI

struct ChatsView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: ChatsViewModel
    @EnvironmentObject var mainViewModel: MainViewModel

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading) {
            headerView

            filtersView

            chatsView

            Spacer()
        }
        .background(Constants.Colors.white)
        .emptyState(isEmpty: viewModel.checkEmptyState(), title: viewModel.emptyStateTitle(), text: viewModel.emptyStateMessage())
        .refreshable {
            viewModel.refreshChats()
        }
        .onAppear {
            viewModel.getAllChats()
        }
        .loadingView(isLoading: viewModel.isLoading)
    }

    private var headerView: some View {
        HStack {
            Text("Messages")
                .font(Constants.Fonts.h1)
                .foregroundStyle(Constants.Colors.black)

            Spacer()
        }
        .padding(.horizontal, 25)
    }

    private var filtersView: some View {
        HStack {
            ForEach(Constants.chats, id: \.id) { filter in
                let unreadCount: Int = {
                    if filter.title == ChatTab.purchases.rawValue {
                        return viewModel.purchaseUnread
                    } else if filter.title == ChatTab.offers.rawValue {
                        return viewModel.offerUnread
                    } else {
                        return 0
                    }
                }()
                
                FilterButton(filter: filter, unreadChats: unreadCount, isSelected: viewModel.selectedTab.rawValue == filter.title) {
                    if filter.title == ChatTab.purchases.rawValue {
                        viewModel.selectedTab = .purchases
                    } else if filter.title == ChatTab.offers.rawValue {
                        viewModel.selectedTab = .offers
                    } else {
                        viewModel.selectedTab = .archived
                    }
                }
            }
        }
        .padding(.leading, Constants.Spacing.horizontalPadding)
        .padding(.vertical, 1)
    }

    private var chatsView: some View {
        ScrollView(.vertical) {
            VStack(alignment: .center, spacing: 24) {
                ForEach(currentChats) { chat in
                    chatPreviewRow(chat: chat, isArchived: viewModel.selectedTab == .archived)
                }
            }
            .padding(.top, 12)

            Spacer()
        }
        .frame(width: UIScreen.width)
    }
    
    private var currentChats: [Chat] {
        switch viewModel.selectedTab {
        case .purchases:
            return viewModel.purchaseChats
        case .offers:
            return viewModel.offerChats
        case .archived:
            return viewModel.archivedChats
        }
    }

    private func chatPreviewRow(chat: Chat, isArchived: Bool = false) -> some View {
        HStack(spacing: 12) {
            KFImage(chat.other.photoUrl)
                .placeholder {
                    ShimmerView()
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                }
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                .opacity(isArchived ? 0.7 : 1.0)

            VStack(alignment: .leading) {
                HStack {
                    Text("\(chat.other.givenName)")
                        .font(Constants.Fonts.title1)
                        .foregroundStyle(isArchived ? Constants.Colors.secondaryGray : Constants.Colors.black)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(chat.post.title)
                        .font(Constants.Fonts.title4)
                        .foregroundStyle(Constants.Colors.secondaryGray)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Constants.Colors.stroke, lineWidth: 0.75)
                        }
                }

                HStack(spacing: 0) {
                    if isArchived {
                        Text("Completed")
                            .font(Constants.Fonts.title4)
                            .foregroundStyle(Constants.Colors.resellPurple.opacity(0.7))
                        
                        Text(" • ")
                            .foregroundStyle(Constants.Colors.secondaryGray)
                    }
                    
                    Text(chat.lastMessage)
                        .font(Constants.Fonts.title4)
                        .foregroundStyle(Constants.Colors.secondaryGray)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(" • ")

                    Text(Date.timeAgo(from: chat.updatedAt))
                        .font(Constants.Fonts.title4)
                        .foregroundStyle(Constants.Colors.secondaryGray)
                }

            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(Constants.Colors.inactiveGray)
        }
        .padding(.horizontal, 15)
        .padding(.leading, 15)
        .background(Constants.Colors.white)
        .overlay(alignment: .leading) {
            if !isArchived && !chat.messages.filter({ !$0.read && !$0.mine }).isEmpty {
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(Constants.Colors.resellPurple)
                    .padding(.leading, 8)
            }
        }
        .onTapGesture {
            guard let me = GoogleAuthManager.shared.user else {
                GoogleAuthManager.shared.logger.error("Error in \(#file) \(#function): User not available.")
                return
            }

            viewModel.selectedChat = chat
            viewModel.getSelectedChatPost { listing in
                guard let seller = listing.user else {
                    NetworkManager.shared.logger.error("Error in \(#file) \(#function): User not found in post. Can't push messages view.")
                    return
                }

                let buyer = seller.firebaseUid == me.firebaseUid ? chat.other : me

                let chatInfo = ChatInfo(
                    listing : listing,
                    buyer: buyer,
                    seller: seller
                )

                router.push(.messages(chatInfo: chatInfo))
            }
        }
    }

}

