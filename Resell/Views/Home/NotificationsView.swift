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

        
    var body: some View {
        VStack {
            filtersView
                .padding(.leading, 15)
            Text("New")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 30)
                .padding(.vertical, 10)
            List(viewModel.filteredNotifications, id: \.data.messageId) { notification in
                notificationView(for: notification)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }
            .listStyle(PlainListStyle())
        }
        .padding(.top, 5)
        .padding(.vertical, 1)
        .navigationTitle("Notifications")
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
                Text("5 days ago")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.leading, 20)
            Spacer()
        }
        .padding(15)
        .padding(.horizontal, 15)
        .background(notification.isRead ? Color.white : Color.purple.opacity(0.1))
        .swipeActions(edge: .leading) {
            Button(action: {
                viewModel.markAsRead(notification: notification)
            }) {
                Image("read-notification")
            }
            .tint(Color.purple.opacity(0.7))
        }
    }
    
    private func notifText(for notification: Notifications) -> some View {
        switch notification.data.type {
        case "message":
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

