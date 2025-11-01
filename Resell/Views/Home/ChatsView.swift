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
                FilterButton(filter: filter, unreadChats: 0, isSelected: viewModel.selectedTab == filter.title) {
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
//                ForEach(viewModel.chats) { chat in
//                    HStack(spacing: 12) {
//                        Circle()
//                        // TODO: Implement Read vs Unread messages
//                            .foregroundStyle(false ? Constants.Colors.resellPurple : Constants.Colors.white)
//                            .frame(width: 10, height: 10)
//
//                        KFImage(chat.avatarUrl)
//                            .placeholder {
//                                ShimmerView()
//                                    .frame(width: 52, height: 52)
//                                    .clipShape(Circle())
//                            }
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 52, height: 52)
//                            .clipShape(Circle())
//
//                        VStack(alignment: .leading) {
//                            HStack {
//                                Text(chat.name)
//                                    .font(Constants.Fonts.title1)
//                                    .foregroundStyle(Constants.Colors.black)
//
//                                Text(chat.name)
//                                    .font(Constants.Fonts.title4)
//                                    .foregroundStyle(Constants.Colors.secondaryGray)
//                                    .padding(.horizontal, 8)
//                                    .padding(.vertical, 4)
//                                    .overlay {
//                                        RoundedRectangle(cornerRadius: 12)
//                                            .stroke(Constants.Colors.stroke, lineWidth: 0.75)
//                                    }
//                            }
//
//                            Text(chat.lastMessage)
//                                .font(Constants.Fonts.title4)
//                                .foregroundStyle(Constants.Colors.secondaryGray)
//                        }
//
//                        Spacer()
//
//                        Image(systemName: "chevron.right")
//                            .foregroundStyle(Constants.Colors.inactiveGray)
//                    }
//                    .padding(.horizontal, 15)
//                    .background(Constants.Colors.white)
//                    .onTapGesture {
//                        router.push(.messages)
//                    }
//                }
            }
            .padding(.top, 24)
        }
    }

}
