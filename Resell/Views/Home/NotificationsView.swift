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
    @State private var showTestMenu = false
    
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
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading notifications...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
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
                            ForEach(items) { notification in
                                notificationView(for: notification)
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .listRowSeparator(.hidden)
                .refreshable {
                    viewModel.fetchNotifications()
                }
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
                    
                    Button("Retry") {
                        viewModel.fetchNotifications()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Constants.Colors.resellPurple)
                }
                .frame(maxWidth: 312, maxHeight: .infinity, alignment: .center)
                .offset(y: -60)
            }
        }
        .padding(.top, 5)
        .padding(.vertical, 1)
        .navigationTitle("Notifications")
        .toolbar {
            // Test notification button (for development)
            #if DEBUG
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Section("Test Notifications") {
                        Button("📬 Test Messages") {
                            viewModel.createTestNotification(type: "messages")
                        }
                        Button("📋 Test Requests") {
                            viewModel.createTestNotification(type: "requests")
                        }
                        Button("🔖 Test Bookmarks") {
                            viewModel.createTestNotification(type: "bookmarks")
                        }
                        Button("💰 Test Transactions") {
                            viewModel.createTestNotification(type: "transactions")
                        }
                    }
                    
                    Divider()
                    
                    Button("🧪 Load Dummy Data") {
                        viewModel.loadDummyData()
                    }
                    
                    Button("🔄 Refresh from Server") {
                        viewModel.fetchNotifications()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            #endif
        }
        .onAppear {
            viewModel.fetchNotifications()
        }
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
            // Use notification image if available, otherwise placeholder
            AsyncImage(url: URL(string: notification.data.imageUrl ?? notification.data.sellerPhotoUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: notificationIcon(for: notification.data.resolvedType))
                    .font(.system(size: 24))
                    .foregroundColor(Constants.Colors.resellPurple)
                    .frame(width: 56, height: 56)
                    .background(Constants.Colors.wash)
            }
            .frame(width: 56, height: 56)
            .cornerRadius(5)
            .clipped()
            
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
        .onTapGesture {
            viewModel.markAsRead(notification: notification)
            // Navigate based on notification type
            handleNotificationTap(notification)
        }
        .listRowBackground(
            (notification.read ? Color.white : Constants.Colors.resellPurple.opacity(0.1))
        )
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: {
                viewModel.markAsRead(notification: notification)
            }) {
                Image("read-notification")
            }
            .tint(Constants.Colors.resellPurple.opacity(0.7))
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: {
                viewModel.removeNotification(notification: notification)
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
            }
            .tint(.red)
        }
    }
    
    private func notificationIcon(for type: String) -> String {
        switch type.lowercased() {
        case "messages": return "message.fill"
        case "requests": return "list.bullet.rectangle"
        case "bookmarks": return "bookmark.fill"
        case "transactions": return "creditcard.fill"
        default: return "bell.fill"
        }
    }
    
    private func handleNotificationTap(_ notification: Notifications) {
        // TODO: Navigate to appropriate screen based on notification type
        // For now, just mark as read
        switch notification.data.resolvedType.lowercased() {
        case "messages":
            if let chatId = notification.data.chatId {
                print("Navigate to chat: \(chatId)")
                // router.push(.chat(id: chatId))
            }
        case "bookmarks", "transactions":
            if let postId = notification.data.postId {
                print("Navigate to post: \(postId)")
                // router.push(.product(id: postId))
            }
        default:
            break
        }
    }
    
    private func notifText(for notification: Notifications) -> some View {
        // Use the notification body directly from the API
        // The backend already formats nice messages like "Test User sent you a message about 'iPhone 13 Pro'"
        switch notification.data.resolvedType.lowercased() {
        case "messages":
            if let sellerUsername = notification.data.sellerUsername,
               let postTitle = notification.data.postTitle {
                return Text(sellerUsername).bold() + Text(" sent you a message about ") + Text("'\(postTitle)'").bold()
            }
            return Text(notification.body)
        case "requests":
            if let postTitle = notification.data.postTitle {
                return Text("Your request for ") + Text(postTitle).bold() + Text(" has been met")
            }
            return Text(notification.body)
        case "bookmarks":
            if let sellerUsername = notification.data.sellerUsername,
               let postTitle = notification.data.postTitle {
                return Text(sellerUsername).bold() + Text(" discounted ") + Text(postTitle).bold()
            }
            return Text(notification.body)
        case "transactions":
            if let postTitle = notification.data.postTitle {
                return Text("Transaction update for ") + Text(postTitle).bold()
            }
            return Text(notification.body)
        default:
            return Text(notification.body)
        }
    }
}

