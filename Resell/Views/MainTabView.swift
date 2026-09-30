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
                        mainView
                        .transition(.opacity)
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
                default:
                    EmptyView()
                }
            }
        }
        .tint(Constants.Colors.resellPurple)
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

    private var mainView: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house", value: 0) {
                HomeView()
            }

            Tab("Messages", systemImage: "message", value: 1) {
                ChatsView()
                    .environmentObject(chatsViewModel)
            }
            .badge(chatsViewModel.totalUnread)

            Tab("Profile", systemImage: "person", value: 2) {
                ProfileView()
            }
        }
        .tint(Constants.Colors.resellPurple)
        // .never forces the bar back to full size — pulsed when a tab root's scroll
        // crosses back above the top breakpoint, since the system only re-expands
        // on fast flings. At rest the bar stays armed with .onScrollDown so any
        // downward gesture minimizes it natively regardless of speed.
        .tabBarMinimizeBehavior(mainViewModel.expandsTabBar ? .never : .onScrollDown)
        .onChange(of: selection) { _, _ in
            mainViewModel.pulseExpandTabBar()
        }
        // Detects taps on the minimized tab bar pill (bottom-leading corner) so the
        // floating add button rises together with the manually re-expanded bar.
        .background(
            MinimizedTabBarTapObserver {
                mainViewModel.handleManualTabBarExpansion()
            }
            .frame(width: 0, height: 0)
        )
        // Tab-root toolbars are defined here, on the outer NavigationStack's root,
        // because toolbar items inside non-initial TabView tabs don't reliably
        // propagate to the enclosing stack's navigation bar.
        .toolbar {
            tabRootToolbar
        }
    }

    @ToolbarContentBuilder
    private var tabRootToolbar: some ToolbarContent {
        if selection == 0 {
            ToolbarItem(placement: .topBarLeading) {
                Text("resell")
                    .font(Constants.Fonts.resellHeader)
                    .foregroundStyle(Constants.Colors.resellGradient)
                    .fixedSize()
            }
            .sharedBackgroundVisibility(.hidden)

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.push(.search(nil))
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Constants.Colors.black)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.push(.notifications)
                } label: {
                    Image(systemName: "bell")
                        .foregroundStyle(Constants.Colors.black)
                }
            }
        } else if selection == 1 {
            ToolbarItem(placement: .topBarLeading) {
                Text("Messages")
                    .font(Constants.Fonts.h1)
                    .foregroundStyle(Constants.Colors.black)
                    .fixedSize()
            }
            .sharedBackgroundVisibility(.hidden)
        } else {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    router.push(.settings(false))
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Constants.Colors.black)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.push(.availability)
                } label: {
                    Image(systemName: "calendar")
                        .foregroundStyle(Constants.Colors.black)
                }
            }
        }
    }
}

// MARK: - Minimized Tab Bar Tap Detection

/// Installs a passive, non-consuming tap recognizer on the window to notice taps
/// in the minimized tab bar pill's region (bottom-leading corner). SwiftUI exposes
/// no state for the bar's minimized/expanded presentation, so this is how floating
/// controls learn the user manually re-expanded the bar by tapping the pill.
private struct MinimizedTabBarTapObserver: UIViewRepresentable {
    let onTap: () -> Void

    func makeUIView(context: Context) -> TapObserverUIView {
        let view = TapObserverUIView()
        view.onBottomLeadingTap = onTap
        return view
    }

    func updateUIView(_ uiView: TapObserverUIView, context: Context) {
        uiView.onBottomLeadingTap = onTap
    }
}

final class TapObserverUIView: UIView, UIGestureRecognizerDelegate {
    var onBottomLeadingTap: (() -> Void)?

    private weak var recognizer: UITapGestureRecognizer?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        isUserInteractionEnabled = false
        guard let window, recognizer == nil else { return }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        window.addGestureRecognizer(tap)
        recognizer = tap
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let window = gesture.view as? UIWindow ?? window else { return }
        let location = gesture.location(in: window)
        let bounds = window.bounds
        // Bottom-leading corner only: the minimized pill's zone. Excludes the
        // trailing side so taps on the floating add button never trigger this.
        if location.y > bounds.height - 80, location.x < bounds.width * 0.4 {
            onBottomLeadingTap?()
        }
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
