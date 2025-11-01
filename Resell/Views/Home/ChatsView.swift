//
//  ChatsView.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

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
                FilterButton(filter: filter, unreadChats: viewModel.unreadMessages[filter.title] ?? 0, isSelected: viewModel.selectedTab == filter.title) {
                    viewModel.selectedTab = filter.title
                    viewModel.unreadMessages[filter.title] = 0
                }
            }
        }
        .padding(.leading, Constants.Spacing.horizontalPadding)
        .padding(.vertical, 1)
    }

    private var chatsView: some View {
        ScrollView(.vertical) {
            VStack(spacing: 24) {
                ForEach(viewModel.chats, id: \.self.0) { chat in
                    HStack(spacing: 12) {
                        Circle()
                            .foregroundStyle(chat.5 ? Constants.Colors.resellPurple : Constants.Colors.white)
                            .frame(width: 10, height: 10)

                        Image(chat.2)
                            .resizable()
                            .frame(width: 52, height: 52)
                            .clipShape(.circle)

                        VStack(alignment: .leading) {
                            HStack {
                                Text(chat.1)
                                    .font(Constants.Fonts.title1)
                                    .foregroundStyle(Constants.Colors.black)

                                Text(chat.3)
                                    .font(Constants.Fonts.title4)
                                    .foregroundStyle(Constants.Colors.secondaryGray)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Constants.Colors.stroke, lineWidth: 0.75)
                                    }
                            }

                            Text(chat.4)
                                .font(Constants.Fonts.title4)
                                .foregroundStyle(Constants.Colors.secondaryGray)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(Constants.Colors.inactiveGray)
                    }
                    .padding(.horizontal, 15)
                    .background(Constants.Colors.white)
                    .onTapGesture {
                        router.push(.messages)
                    }
                }
            }
            .padding(.top, 24)
        }
    }
}
