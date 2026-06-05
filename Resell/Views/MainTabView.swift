//
//  MainTabView.swift
//  Resell
//
//  Created by Richie Sun on 10/9/24.
//

import SwiftUI

struct MainTabView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router

    @Binding var isHidden: Bool
    @Binding var selection: Int

    // MARK: - ViewModels

    @EnvironmentObject private var chatsViewModel: ChatsViewModel
    @EnvironmentObject private var mainViewModel: MainViewModel
    @EnvironmentObject private var newListingViewModel: NewListingViewModel
    @EnvironmentObject private var onboardingViewModel: SetupProfileViewModel
    @EnvironmentObject private var reportViewModel: ReportViewModel

    // MARK: - UI

    var body: some View {
        NavigationStack(path: $router.path) {
                Group {
                    if mainViewModel.userDidLogin {
                        ZStack(alignment: .bottom) {
                            mainView
                                .safeAreaInset(edge: .bottom, spacing: 0) {
                                    Color.clear.frame(height: isHidden ? 0 : 90)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)

                            if !isHidden {
                                tabBarView
                            }
                        }
                        .ignoresSafeArea(edges: .bottom)
                        .transition(.opacity)
                        .background(.white)
                        .environmentObject(router)
                        .onAppear {
                            // Start listening to chat updates as soon as the
                            // user lands on the main shell so the tab-bar
                            // unread badge is populated even if they never
                            // open the messages tab.
                            chatsViewModel.getAllChats()
                        }
                        .onChange(of: mainViewModel.userDidLogin) { didLogin in
                            if didLogin {
                                chatsViewModel.getAllChats()
                            }
                        }
                    } else {
                        LoginView()
                            .transition(.opacity)
                            .environmentObject(onboardingViewModel)
                            .environmentObject(router)
                    }
            }
            .navigationDestination(for: Router.Route.self) { route in
                switch route {
                case .newListingDetails:
                    NewListingDetailsView()
                        .environmentObject(newListingViewModel)
                case .newListingImages:
                    NewListingImagesView()
                        .environmentObject(newListingViewModel)
                case .newRequest:
                    NewRequestView()
                case .messages(let chatInfo):
                    MessagesView(chatInfo: chatInfo)
                case .discover:
                    SuggestionsView()
                case .productDetails(let item):
                    ProductDetailsView(post: item)
                        .ignoresSafeArea(edges: .top)
                case .reportConfirmation:
                    ReportConfirmationView()
                        .environmentObject(reportViewModel)
                case .reportDetails:
                    ReportDetailsView()
                        .environmentObject(reportViewModel)
                case .reportOptions(let type, let id):
                    ReportOptionsView(type: type, id: id)
                        .environmentObject(reportViewModel)
                case .search(let id):
                    SearchView(userID: id)
                case .settings(let isAccountSettings):
                    SettingsView(isAccountSettings: isAccountSettings)
                case .blockedUsers:
                    BlockedUsersView()
                case .editProfile:
                    EditProfileView()
                case .feedback:
                    SendFeedbackView()
                case .detailedFilter(let filter):
                    DetailedFilterView(filter: filter)
                case .saved:
                    SavedView()
                case .availability:
                    AvailabilitySettingsView()
               case .notifications:
                   NotificationsView()
                case .login:
                    LoginView()
                        .environmentObject(onboardingViewModel)
                case .profile(let id):
                    ExternalProfileView(userID: id)
                case .followList(let userID, let username, let initialTab):
                    FollowListView(userID: userID, username: username, initialTab: initialTab)
                case .setupProfile:
                    SetupProfileView(userDidLogin: $mainViewModel.userDidLogin, user: GoogleAuthManager.shared.user)
                        .environmentObject(onboardingViewModel)
                case .venmo:
                    VenmoView(userDidLogin: $mainViewModel.userDidLogin)
                        .environmentObject(onboardingViewModel)
                case .completedTransaction(let transaction):
                    CompletedTransactionView(transaction: transaction)
                case .reviewTesting:
                    ReviewTestingView()
                default:
                    EmptyView()
                }
            }
        }
    }

    private var mainView: some View {
        ZStack {
            if selection == 0 {
                HomeView()
            } else if selection == 1 {
                explorePlaceholder
            } else if selection == 2 {
                SellView()
            } else if selection == 3 {
                ChatsView()
                    .environmentObject(chatsViewModel)
            } else if selection == 4 {
                ProfileView()
            }
        }
    }

    private var explorePlaceholder: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "safari")
                .font(.system(size: 48))
                .foregroundStyle(Constants.Colors.inactiveGray)
            Text("Explore")
                .font(Constants.Fonts.h2)
                .foregroundStyle(Constants.Colors.black)
            Text("Coming soon")
                .font(Constants.Fonts.body2)
                .foregroundStyle(Constants.Colors.secondaryGray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.Colors.white)
    }

    // MARK: - Tab Bar

    private struct TabBarConfig {
        let label: String
        let icon: String
        let activeIcon: String
    }

    private let tabBarConfigs: [TabBarConfig] = [
        TabBarConfig(label: "Home",     icon: "house",    activeIcon: "house.fill"),
        TabBarConfig(label: "Explore",  icon: "safari",   activeIcon: "safari.fill"),
        TabBarConfig(label: "Sell",     icon: "tag",      activeIcon: "tag.fill"),
        TabBarConfig(label: "Messages", icon: "paperplane",  activeIcon: "paperplane.fill"),
        TabBarConfig(label: "Profile",  icon: "person.crop.circle",   activeIcon: "person.crop.circle.fill"),
    ]

    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(tabBarConfigs.indices, id: \.self) { index in
                let config = tabBarConfigs[index]
                let isSelected = selection == index
                let badgeCount = index == 3 ? chatsViewModel.totalUnread : 0

                Button {
                    selection = index
                } label: {
                    HStack(spacing: isSelected ? 6 : 0) {
                        Image(systemName: isSelected ? config.activeIcon : config.icon)
                            .font(.system(size: 17, weight: isSelected ? .semibold : .regular))

                        if isSelected {
                            Text(config.label)
                                .font(.custom("Rubik-Medium", size: 13))
                                .fixedSize()
                                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        }
                    }
                    .foregroundStyle(isSelected ? Color.white : Constants.Colors.tabBarInactive)
                    .padding(.vertical, 10)
                    .padding(.horizontal, isSelected ? 18 : 14)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(Constants.Colors.resellGradient)
                                .opacity(0.7)
                        }
                    }
                    .clipShape(Capsule())
                    .overlay(alignment: .topTrailing) {
                        if badgeCount > 0 {
                            Text(badgeCount > 99 ? "99+" : "\(badgeCount)")
                                .font(.custom("Roboto-Medium", size: 10))
                                .foregroundStyle(Constants.Colors.white)
                                .padding(.horizontal, 5)
                                .frame(minWidth: 16, minHeight: 16)
                                .background(Constants.Colors.errorRed)
                                .clipShape(.capsule)
                                .offset(x: isSelected ? 0 : 8, y: -6)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                if index < tabBarConfigs.count - 1 {
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 50, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 50, style: .continuous)
                        .fill(Color.white.opacity(0.6))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 50, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .frame(width: UIScreen.width)
        .background(Color.clear)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut, value: isHidden)
    }
}
