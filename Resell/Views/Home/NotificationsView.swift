//
//  NotificationsView.swift
//  Resell
//
//  Created by Angelina Chen on 11/26/24.
//

import SwiftUI

struct NotificationsView: View {
    
    // MARK: Properties
    
    @EnvironmentObject var router: Router
    @StateObject private var viewModel = NotificationsViewModel()
    
    private let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f
    }()

    private func timeAgo(_ date: Date) -> String {
        relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
    
    var body: some View {
        VStack {
            filtersView
                .padding(.leading, 15)
                .zIndex(1)
            
            switch viewModel.loadState {
            case .idle:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .offset(y: -60)
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .offset(y: -60)
            case .success:
                List {
                    ForEach(NotificationSection.allCases) { section in
                        if let items = viewModel.groupedFilteredNotifications[section], !items.isEmpty {
                            Text(section.rawValue)
                                .font(.custom("Rubik-Medium", size: 18))
                                .foregroundColor(.primary)
                                .textCase(nil)
                                .padding(.leading, 8)
                                .padding(.top, 5)
                                .listRowSeparator(.hidden)
                            ForEach(items, id: \.data.messageId) { notification in
                                notificationView(for: notification)
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .listRowSeparator(.hidden)
            case .empty:
                VStack (alignment: .center, spacing: 16) {
                    Text("You're all caught up!")
                        .font(.custom("Rubik-Medium", size: 22))
                        .foregroundStyle(.black)
                    Text("No new notifications right now")
                        .font(.custom("Rubik", size: 18))
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .offset(y: -60)
            case .error:
                VStack (alignment: .center, spacing: 16) {
                    Text("Something went wrong!")
                        .font(.custom("Rubik-Medium", size: 22))
                        .foregroundStyle(.black)
                    Text("Please try again. If this problem persists, feel free to let us know")
                        .font(.custom("Rubik", size: 18))
                        .foregroundStyle(.gray)
                }
                .frame(maxWidth: 312, maxHeight: .infinity, alignment: .center)
                .offset(y: -60)
            }
        }
        .padding(.top, 5)
        .padding(.vertical, 1)
        .navigationTitle("Notifications")
        // MARK: - Uncomment when confirm notification data in backend
//        .onAppear {
//            viewModel.fetchNotifications()
//        }
    }
    
    // Creates the filter for notifications sorting
    private var filtersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Constants.notificationFilters, id: \.id) { filter in
                    FilterButton(
                        filter: filter, isSelected: viewModel.selectedTab == filter.title
                    ) {
                        viewModel.selectedTab = filter.title
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 1)
            }
            .padding(.leading, 15)
        }
    }
    
    // Creates individual notification rows / components
    private func notificationView(for notification: Notifications) -> some View {
        HStack(alignment: .top) {
            Image("justin_long")
                .resizable()
                .frame(width: 56, height: 56)
                .cornerRadius(5)
            
            VStack(alignment: .leading) {
                Spacer()
                notifText(for: notification)
                    .font(.system(size: 14))
                Text(timeAgo(notification.createdAt))
                    .font(.footnote)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.leading, 10)
            Spacer()
        }
        .padding(12)
        .padding(.horizontal, 12)
        .contentShape(Rectangle())
        .background(notification.isRead ? Color.white : Constants.Colors.resellPurple.opacity(0.1))
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: {
                viewModel.markAsRead(notification: notification)
            }) {
                Image("read-notification")
            }
            .tint(Constants.Colors.resellPurple.opacity(0.7))
        }
    }
    
    private func notifText(for notification: Notifications) -> some View {
        switch notification.data.type {
        case "messages":
            return Text(notification.userID).bold() + Text(" sent you a message")
        case "requests":
            return Text("Your request for ")
                + Text(notification.data.messageId).bold()
                + Text(" has been met")
        case "bookmarks":
            return Text("\(notification.userID) discounted ")
                + Text(notification.data.messageId).bold()
        case "your listings":
            return Text("\(notification.userID) bookmarked ")
                + Text(notification.data.messageId).bold()
        default:
            return Text(notification.title)
        }
    }
}

