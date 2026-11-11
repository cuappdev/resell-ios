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

    @State private var isSelectionLensLifted = false
    @State private var selectionLensSettleTask: Task<Void, Never>?

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
            swellSelectionLens()
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
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
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
        case .eventSpace(let event):
            EventSpaceView(event: event)
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

    private static let tabBarIconFade = Animation.easeInOut(duration: 0.25)
    private static let avatarDiameter: CGFloat = 28
    private static let avatarRingWidth: CGFloat = 1.5
    private static let selectedAvatarRingWidth: CGFloat = 2.5

    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(Router.Tab.allCases, id: \.rawValue) { tab in
                tabBarButton(for: tab)
            }
        }
        .background {
            TabBarSelectionLens(selectedIndex: selectedTab.rawValue, isLifted: isSelectionLensLifted)
        }
        .padding(Constants.Spacing.spacing8)
        // Keep the bar intrinsic-height; an unconstrained clear fill previously
        // expanded to the full ZStack height and blew up the capsule.
        .fixedSize(horizontal: false, vertical: true)
        .modifier(TabBarGlassModifier())
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .padding(.bottom, 20)
        .frame(width: UIScreen.width)
        .fixedSize(horizontal: false, vertical: true)
        .allowsHitTesting(true)
    }

    /// Tapping the selected tab goes through `Router.reselect(_:)`, which pops it to its root
    /// or scrolls the root back to the top; any other tab switches to it.
    private func tabBarButton(for tab: Router.Tab) -> some View {
        let isSelected = selectedTab == tab
        let badgeCount = tab == .chats ? chatsViewModel.totalUnread : 0

        return Button {
            if isSelected {
                router.reselect(tab)
            } else {
                router.activeTab = tab
                selection = tab.rawValue
            }
        } label: {
            tabBarIcon(for: tab, isSelected: isSelected)
                .overlay(alignment: .topTrailing) {
                    if badgeCount > 0 {
                        unreadBadge(count: badgeCount)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: Self.avatarDiameter + Self.selectedAvatarRingWidth * 2)
                .padding(.vertical, Constants.Spacing.spacing8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tabBarLabel(for: tab))
        .accessibilityValue(badgeCount > 0 ? "\(badgeCount) unread" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The tabs are icon-only, so this is what VoiceOver reads for each one.
    private func tabBarLabel(for tab: Router.Tab) -> String {
        switch tab {
        case .home: "Home"
        case .explore: "Explore"
        case .sell: "Sell"
        case .chats: "Messages"
        case .profile: "Profile"
        }
    }

    @ViewBuilder
    private func tabBarIcon(for tab: Router.Tab, isSelected: Bool) -> some View {
        switch tab {
        case .home:
            tabBarAsset("tab-home", isSelected: isSelected)
        case .explore:
            tabBarAsset("tab-search", isSelected: isSelected)
        case .sell:
            tabBarAsset("tab-sell", isSelected: isSelected)
        case .chats:
            tabBarAsset("tab-messages", isSelected: isSelected)
        case .profile:
            profileTabImage(isSelected: isSelected)
        }
    }

    /// Cross-fades between an icon's idle asset and its `-selected` one.
    private func tabBarAsset(_ name: String, isSelected: Bool) -> some View {
        ZStack {
            Image(name)
                .opacity(isSelected ? 0 : 1)
            Image("\(name)-selected")
                .opacity(isSelected ? 1 : 0)
        }
        .animation(Self.tabBarIconFade, value: isSelected)
    }

    /// Lifts the selection lens as it sets off, then lets it sink back into the
    /// resting pill while it is still arriving, so the two motions read as one.
    private func swellSelectionLens() {
        selectionLensSettleTask?.cancel()
        isSelectionLensLifted = true
        selectionLensSettleTask = Task {
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            isSelectionLensLifted = false
        }
    }

    private func unreadBadge(count: Int) -> some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(Constants.Fonts.badge)
            .foregroundStyle(Constants.Colors.white)
            .padding(.horizontal, 5)
            .frame(minWidth: 16, minHeight: 16)
            .background(Constants.Colors.errorRed)
            .clipShape(.capsule)
            .fixedSize()
            .offset(x: 8, y: -6)
    }

    /// The user's avatar (or the placeholder when they have none), ringed in gray
    /// while idle and in the tab bar gradient while Profile is selected.
    private func profileTabImage(isSelected: Bool) -> some View {
        Image(uiImage: currentUser.profilePic)
            .resizable()
            .scaledToFill()
            .frame(width: Self.avatarDiameter, height: Self.avatarDiameter)
            .clipShape(Circle())
            .overlay {
                avatarRing(Constants.Colors.tabBarInactive, width: Self.avatarRingWidth)
                    .opacity(isSelected ? 0 : 1)
            }
            .overlay {
                avatarRing(Constants.Colors.tabBarActiveGradient, width: Self.selectedAvatarRingWidth)
                    .opacity(isSelected ? 1 : 0)
            }
            .animation(Self.tabBarIconFade, value: isSelected)
    }

    /// A ring drawn just outside the avatar's edge.
    private func avatarRing<Style: ShapeStyle>(_ style: Style, width: CGFloat) -> some View {
        Circle()
            .strokeBorder(style, lineWidth: width)
            .padding(-width)
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

/// The highlight behind the selected tab. Its two ends chase the selection on springs of
/// different stiffness, so the pill stretches like a liquid while it travels and closes
/// back up as it lands. While `isLifted` it swells into a glass lens, like the iOS 26
/// system tab bar (the glass needs iOS 26).
private struct TabBarSelectionLens: View {
    let selectedIndex: Int
    let isLifted: Bool

    private static let headSpring = Animation.spring(response: 0.34, dampingFraction: 0.78)
    private static let tailSpring = Animation.spring(response: 0.5, dampingFraction: 0.85)
    private static let liftSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    private static let settleSpring = Animation.spring(response: 0.45, dampingFraction: 0.6)
    /// How much larger than its slot the lens grows while lifted.
    private static let liftedScale = CGSize(width: 1.15, height: 1.35)

    var body: some View {
        GeometryReader { proxy in
            let slot = selectedSlot(in: proxy.size)
            // Each reader animates on its own spring and hands down the in-flight value,
            // which is the only way to drive one shape from several animations at once.
            AnimatedValueReader(value: slot.minX) { head in
                AnimatedValueReader(value: slot.minX) { tail in
                    AnimatedValueReader(value: isLifted ? 1 : 0) { lift in
                        lens(from: min(head, tail), to: max(head, tail) + slot.width, lift: lift, slot: slot)
                    }
                    .animation(isLifted ? Self.liftSpring : Self.settleSpring, value: isLifted)
                }
                .animation(Self.tailSpring, value: selectedIndex)
            }
            .animation(Self.headSpring, value: selectedIndex)
        }
    }

    private func selectedSlot(in size: CGSize) -> CGRect {
        let tabWidth = size.width / CGFloat(Router.Tab.allCases.count)
        return CGRect(x: tabWidth * CGFloat(selectedIndex), y: 0, width: tabWidth, height: size.height)
    }

    /// The pill spanning `leading...trailing`, grown about its centre by `lift` (0 at
    /// rest, 1 fully lifted; the settle spring overshoots a little either side).
    private func lens(from leading: CGFloat, to trailing: CGFloat, lift: CGFloat, slot: CGRect) -> some View {
        let growth = CGSize(
            width: slot.width * (Self.liftedScale.width - 1) * lift,
            height: slot.height * (Self.liftedScale.height - 1) * lift
        )
        return ZStack {
            Capsule()
                .fill(Constants.Colors.tabBarSelection)
            if #available(iOS 26, *) {
                // Its own container keeps the lens a separate glass layer; glass placed
                // directly inside the bar's glass content merged into the bar and never showed.
                GlassEffectContainer {
                    Color.clear
                        .glassEffect(isLifted ? .clear : .identity, in: Capsule())
                }
            }
        }
        .frame(width: trailing - leading + growth.width, height: slot.height + growth.height)
        .offset(x: leading - growth.width / 2, y: -growth.height / 2)
    }
}

/// Re-renders `content` with the in-flight value of `value` on every frame of whatever
/// animation is applied to this view.
private struct AnimatedValueReader<Content: View>: View, Animatable {
    var value: CGFloat
    @ViewBuilder let content: (CGFloat) -> Content

    var animatableData: CGFloat {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        content(value)
    }
}

/// Tinted Liquid Glass capsule behind the floating tab bar that lightens and swells while
/// it is pressed, with a material fallback before iOS 26.
private struct TabBarGlassModifier: ViewModifier {

    /// How much of the tint stays and how far the bar grows while pressed on iOS 26,
    /// measured off what interactive Liquid Glass does to the bar on iOS 27.
    private static let pressedTintOpacity = 0.15
    private static let pressedScale = 1.035
    private static let pressSpring = Animation.spring(response: 0.3, dampingFraction: 0.8)
    private static let shadowRadius: CGFloat = 8
    private static let shadowOffsetY: CGFloat = 4

    @GestureState private var isPressed = false

    // Use a single material/glass layer only — stacking fill + glass + shadow
    // produced a second, slightly larger outline behind the bar.
    func body(content: Content) -> some View {
        let shape = Capsule()
        if #available(iOS 27, *) {
            tinted(content)
                .glassEffect(.regular.interactive(), in: shape)
        } else if #available(iOS 26, *) {
            // iOS 26's interactive glass ends every press with a dip and a flash before
            // snapping back, which flickers across the whole bar, so the press response
            // is drawn here on plain glass instead.
            tinted(content, tintOpacity: isPressed ? Self.pressedTintOpacity : 1)
                .glassEffect(.regular, in: shape)
                .animation(Self.pressSpring) { bar in
                    bar.scaleEffect(isPressed ? Self.pressedScale : 1)
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .updating($isPressed) { _, isPressed, _ in isPressed = true }
                )
        } else {
            tinted(content)
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.strokeBorder(Constants.Colors.black.opacity(0.06), lineWidth: 1))
        }
    }

    /// Backs the bar with white so content behind it stays muted, grays it toward Figma's
    /// body tone, and keeps its empty areas tappable.
    private func tinted(_ content: Content, tintOpacity: Double = 1) -> some View {
        content
            .background {
                ZStack {
                    outerShadow
                    Capsule()
                        .fill(Constants.Colors.tabBarGlassBacking)
                    Capsule()
                        .fill(Constants.Colors.tabBarGlassTint)
                        .opacity(tintOpacity)
                        .animation(Self.pressSpring, value: tintOpacity)
                }
            }
            .contentShape(Capsule())
    }

    /// A drop shadow cut away under the bar, so it darkens only what's around the bar
    /// and doesn't gray the translucent bar itself.
    private var outerShadow: some View {
        Capsule()
            .shadow(color: Constants.Colors.tabBarShadow, radius: Self.shadowRadius, y: Self.shadowOffsetY)
            .mask {
                Rectangle()
                    .padding(-(Self.shadowRadius * 2 + Self.shadowOffsetY))
                    .overlay { Capsule().blendMode(.destinationOut) }
                    .compositingGroup()
            }
    }
}
