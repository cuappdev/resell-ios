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
    @ObservedObject private var currentUser = CurrentUserProfileManager.shared

    // MARK: - UI

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if mainViewModel.userDidLogin {
                    tabNavigation
                        .transition(.opacity)
                } else {
                    loginNavigation
                        .transition(.opacity)
                }
            }

            if showsTabBar {
                tabBarView
                    .zIndex(1)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            router.activeTab = selectedTab
            if mainViewModel.userDidLogin {
                // Start listening to chat updates as soon as the user lands
                // on the main shell so the unread badge stays populated.
                chatsViewModel.getAllChats()
                currentUser.loadProfile()
            }
        }
        .onChange(of: mainViewModel.userDidLogin) { didLogin in
            if didLogin {
                chatsViewModel.getAllChats()
                currentUser.loadProfile(forceRefresh: true)
            } else {
                router.reset()
            }
        }
        .onChange(of: selection) { _ in
            router.activeTab = selectedTab
        }
        .onChange(of: router.path) { _ in
            // Restore tab bar as soon as we leave a conversation — don't wait
            // for MessagesView.onDisappear, which fires after the pop animation.
            if isHidden && !isMessagesRouteActive {
                isHidden = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Constants.Notifications.OpenTransactionDeepLink)) { output in
            guard mainViewModel.userDidLogin else { return }
            guard let tid = output.userInfo?["transactionId"] as? String, !tid.isEmpty else { return }
            Task {
                do {
                    let response = try await NetworkManager.shared.getTransactionById(transactionId: tid)
                    await MainActor.run {
                        if response.transaction.completed {
                            let uid = GoogleAuthManager.shared.user?.firebaseUid
                            if response.transaction.buyer?.firebaseUid == uid {
                                router.push(.completedTransaction(response.transaction))
                            } else {
                                router.push(.notifications)
                            }
                        } else {
                            router.push(.notifications)
                        }
                    }
                } catch {
                    await MainActor.run {
                        router.push(.notifications)
                    }
                }
            }
        }
    }

    private var selectedTab: Router.Tab {
        Router.Tab(rawValue: selection) ?? .home
    }

    private var showsTabBar: Bool {
        mainViewModel.userDidLogin && !isHidden && !isMessagesRouteActive
    }

    private var isMessagesRouteActive: Bool {
        if case .messages = router.lastPushedView() {
            return true
        }
        return false
    }

    private var tabNavigation: some View {
        // Manual tab container — the system TabView still renders its own bar
        // under ours, which showed through the glass as a second outline.
        ZStack {
            ForEach(Router.Tab.allCases, id: \.rawValue) { tab in
                NavigationStack(path: router.pathBinding(for: tab)) {
                    tabRoot(for: tab)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Constants.Colors.white)
                        // Keep bottom clearance even while a conversation is open
                        // (tab bar hidden). Tying this to showsTabBar removed the
                        // inset on push and often failed to restore it on pop.
                        .modifier(TabBarContentInsetModifier(
                            isEnabled: mainViewModel.userDidLogin && !isHidden
                        ))
                        .navigationDestination(for: Router.Route.self) { route in
                            destination(for: route)
                        }
                }
                .opacity(selectedTab == tab ? 1 : 0)
                .allowsHitTesting(selectedTab == tab)
                // Inactive stacks stay mounted so each tab keeps its own history.
                .accessibilityHidden(selectedTab != tab)
            }
        }
    }

    private var loginNavigation: some View {
        NavigationStack(path: router.pathBinding(for: .home)) {
            LoginView()
                .environmentObject(onboardingViewModel)
                .navigationDestination(for: Router.Route.self) { route in
                    destination(for: route)
                }
        }
    }

    @ViewBuilder
    private func tabRoot(for tab: Router.Tab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .explore:
            ExploreView()
        case .sell:
            SellView()
        case .chats:
            ChatsView()
                .environmentObject(chatsViewModel)
        case .profile:
            ProfileView()
        }
    }

    @ViewBuilder
    private func destination(for route: Router.Route) -> some View {
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
        case .recentlyViewed:
            RecentlyViewedView()
        case .dailyPicks:
            DailyPicksView()
        case .trending(let category):
            TrendingView(category: category)
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
        default:
            EmptyView()
        }
    }

    // MARK: - Tab Bar

    private struct TabBarConfig {
        let label: String
        let icon: String
        let activeIcon: String
    }

    private func config(for tab: Router.Tab) -> TabBarConfig {
        switch tab {
        case .home:
            TabBarConfig(label: "Home", icon: "house", activeIcon: "house.fill")
        case .explore:
            TabBarConfig(label: "Explore", icon: "safari", activeIcon: "safari.fill")
        case .sell:
            TabBarConfig(label: "Sell", icon: "tag", activeIcon: "tag.fill")
        case .chats:
            TabBarConfig(label: "Messages", icon: "paperplane", activeIcon: "paperplane.fill")
        case .profile:
            TabBarConfig(label: "Profile", icon: "person.crop.circle", activeIcon: "person.crop.circle.fill")
        }
    }

    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(Router.Tab.allCases, id: \.rawValue) { tab in
                tabBarButton(for: tab)

                if tab != Router.Tab.allCases.last {
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        // Keep the bar intrinsic-height; an unconstrained clear fill previously
        // expanded to the full ZStack height and blew up the capsule.
        .fixedSize(horizontal: false, vertical: true)
        .background {
            Capsule()
                .fill(Constants.Colors.white.opacity(0.001))
        }
        .contentShape(Capsule())
        .modifier(TabBarGlassModifier())
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .padding(.bottom, 20)
        .frame(width: UIScreen.width)
        .fixedSize(horizontal: false, vertical: true)
        .allowsHitTesting(true)
    }

    /// Tapping the selected tab pops its stack to the root; any other tab switches to it.
    private func tabBarButton(for tab: Router.Tab) -> some View {
        let config = config(for: tab)
        let isSelected = selectedTab == tab
        let badgeCount = tab == .chats ? chatsViewModel.totalUnread : 0

        return Button {
            if isSelected {
                router.popToRoot()
            } else {
                router.activeTab = tab
                selection = tab.rawValue
            }
        } label: {
            HStack(spacing: isSelected ? 6 : 0) {
                if tab == .profile && currentUser.hasProfilePicture {
                    profileTabImage
                } else {
                    Image(systemName: isSelected ? config.activeIcon : config.icon)
                        .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                }

                if isSelected {
                    Text(config.label)
                        .font(Constants.Fonts.tabBarLabel)
                        .fixedSize()
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .foregroundStyle(Constants.Colors.black)
            .padding(.vertical, 10)
            .padding(.horizontal, isSelected ? 18 : 14)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Constants.Colors.black.opacity(0.08))
                }
            }
            .clipShape(Capsule())
            .overlay(alignment: .topTrailing) {
                if badgeCount > 0 {
                    unreadBadge(count: badgeCount, isTabSelected: isSelected)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private func unreadBadge(count: Int, isTabSelected: Bool) -> some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(Constants.Fonts.badge)
            .foregroundStyle(Constants.Colors.white)
            .padding(.horizontal, 5)
            .frame(minWidth: 16, minHeight: 16)
            .background(Constants.Colors.errorRed)
            .clipShape(.capsule)
            .offset(x: isTabSelected ? 0 : 8, y: -6)
    }

    private var profileTabImage: some View {
        Image(uiImage: currentUser.profilePic)
            .resizable()
            .scaledToFill()
            .frame(width: 20, height: 20)
            .clipShape(Circle())
    }
}

/// Reserves room at the bottom of a tab's scroll content so it can scroll clear
/// of the floating tab bar.
private struct TabBarContentInsetModifier: ViewModifier {
    let isEnabled: Bool

    /// Floating glass tab bar + bottom padding + breathing room above home indicator.
    private let tabBarScrollClearance: CGFloat = 100

    func body(content: Content) -> some View {
        // Always keep safeAreaInset in the tree — swapping it in/out with
        // `if isEnabled` breaks ScrollView content insets after navigation.
        content.safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: isEnabled ? tabBarScrollClearance : 0)
        }
    }
}

/// Liquid Glass capsule behind the floating tab bar, with a material fallback
/// before iOS 26.
private struct TabBarGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        let shape = Capsule()
        // Use a single material/glass layer only — stacking fill + glass + shadow
        // produced a second, slightly larger outline behind the bar.
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular, in: shape)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.strokeBorder(Constants.Colors.black.opacity(0.06), lineWidth: 1))
                .shadow(color: Constants.Colors.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
    }
}
 
