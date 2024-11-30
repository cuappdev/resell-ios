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
    @StateObject private var viewModel = ChatsViewModel()

    // MARK: - UI

    var body: some View {
        NavigationStack(path: $router.path) {
            VStack(alignment: .leading) {
                headerView
                
                filtersView
                
                chatsView
                
                Spacer()
            }
            .background(Constants.Colors.white)
            .loadingView(isLoading: viewModel.isLoading)
            .refreshable {
                if viewModel.selectedTab == "Purchases" {
                    viewModel.getPurchaceChats()
                } else {
                    viewModel.getOfferChats()
                }
            }
            .onAppear {
                viewModel.getAllChats()
            }
        }
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
                let unreadCount = filter.title == "Purchases" ? viewModel.purchaseUnread : viewModel.offerUnread
                FilterButton(filter: filter, unreadChats: unreadCount, isSelected: viewModel.selectedTab == filter.title) {
                    viewModel.selectedTab = filter.title
                }
            }
        }
        .padding(.leading, Constants.Spacing.horizontalPadding)
        .padding(.vertical, 1)
    }

    private var chatsView: some View {
        ScrollView(.vertical) {
            VStack(spacing: 24) {
                ForEach(viewModel.selectedTab == "Purchases" ? viewModel.purchaseChats : viewModel.offerChats) { chatPreview in
                    HStack(spacing: 12) {
                        KFImage(chatPreview.image)
                            .placeholder {
                                ShimmerView()
                                    .frame(width: 52, height: 52)
                                    .clipShape(Circle())
                            }
                            .resizable()
                            .scaledToFill()
                            .frame(width: 52, height: 52)
                            .clipShape(Circle())

                        VStack(alignment: .leading) {
                            HStack {
                                Text(chatPreview.sellerName)
                                    .font(Constants.Fonts.title1)
                                    .foregroundStyle(Constants.Colors.black)
                                    .lineLimit(1)
                                    .truncationMode(.tail)

                                Text(chatPreview.recentItem)
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
                                Text(chatPreview.recentMessage)
                                    .font(Constants.Fonts.title4)
                                    .foregroundStyle(Constants.Colors.secondaryGray)
                                    .lineLimit(1)
                                    .truncationMode(.tail)

                                Text(" • ")

                                Text(Date.timeAgo(from: chatPreview.recentMessageTime))
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
                        if !chatPreview.viewed {
                            Circle()
                                .frame(width: 10, height: 10)
                                .foregroundStyle(Constants.Colors.resellPurple)
                                .padding(.leading, 8)
                        }
                    }
                    .onTapGesture {
                        viewModel.selectedChat = chatPreview
                        viewModel.updateChatViewed()
                        router.push(.messages)
                    }
                }
            }
            .padding(.top, 24)
        }
    }

}

