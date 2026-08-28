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
            router.activeTab = selection
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
        .onChange(of: selection) { newSelection in
            router.activeTab = newSelection
        }
        .onChange(of: router.path) { path in
            // Restore tab bar as soon as we leave a conversation — don't wait
            // for MessagesView.onDisappear, which fires after the pop animation.
            let isMessages = path.last.map { route in
                if case .messages = route { return true }
                return false
            } ?? false
            if !isMessages && isHidden {
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
        // Manual tab container — avoids the system TabView tab bar that was
        // still rendering under our custom glass bar (double border / ghost pill).
        ZStack {
            ForEach(tabBarConfigs.indices, id: \.self) { tab in
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
                .opacity(selection == tab ? 1 : 0)
                .allowsHitTesting(selection == tab)
                // Keep inactive stacks mounted so each tab retains its navigation path.
                .accessibilityHidden(selection != tab)
            }
        }
    }

    private var loginNavigation: some View {
        NavigationStack(path: router.pathBinding(for: 0)) {
            LoginView()
                .environmentObject(onboardingViewModel)
                .navigationDestination(for: Router.Route.self) { route in
                    destination(for: route)
                }
        }
    }

    @ViewBuilder
    private func tabRoot(for tab: Int) -> some View {
        switch tab {
        case 0:
            HomeView()
        case 1:
            ExploreView()
        case 2:
            SellView()
        case 3:
            ChatsView()
                .environmentObject(chatsViewModel)
        case 4:
            ProfileView()
        default:
            EmptyView()
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
        case .reviewTesting:
            ReviewTestingView()
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
                    if selection == index {
                        router.popToRoot()
                    } else {
                        router.activeTab = index
                        selection = index
                    }
                } label: {
                    HStack(spacing: isSelected ? 6 : 0) {
                        if index == 4 && currentUser.hasProfilePicture {
                            profileTabImage
                        } else {
                            Image(systemName: isSelected ? config.activeIcon : config.icon)
                                .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                        }

                        if isSelected {
                            Text(config.label)
                                .font(.custom("Rubik-Medium", size: 13))
                                .fixedSize()
                                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        }
                    }
                    .foregroundStyle(Color.black)
                    .padding(.vertical, 10)
                    .padding(.horizontal, isSelected ? 18 : 14)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(Color.black.opacity(0.08))
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
        // Keep the bar intrinsic-height; an unconstrained clear fill previously
        // expanded to the full ZStack height and blew up the capsule.
        .fixedSize(horizontal: false, vertical: true)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.001))
        }
        .contentShape(Capsule())
        .modifier(TabBarGlassModifier())
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .padding(.bottom, 20)
        .frame(width: UIScreen.width)
        .fixedSize(horizontal: false, vertical: true)
        .allowsHitTesting(true)
    }

    private var profileTabImage: some View {
        Image(uiImage: currentUser.profilePic)
            .resizable()
            .scaledToFill()
            .frame(width: 20, height: 20)
            .clipShape(Circle())
    }
}

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
                .overlay(shape.strokeBorder(Color.black.opacity(0.06), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
    }
}
 
