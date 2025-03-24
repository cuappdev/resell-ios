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
            VStack {
                if mainViewModel.userDidLogin {
                    ZStack(alignment: .bottom) {
                        mainView

                        if !isHidden {
                            tabBarView
                        }
                    }
                    .transition(.opacity)
                    .environmentObject(router)
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
                case .productDetails(let item):
                    ProductDetailsView(post: item)
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
                case .notifications:
                    NotificationsSettingsView()
                case .login:
                    LoginView()
                        .environmentObject(onboardingViewModel)
                case .profile(let id):
                    ExternalProfileView(userID: id)
                case .setupProfile:
                    SetupProfileView(userDidLogin: $mainViewModel.userDidLogin, user: GoogleAuthManager.shared.user)
                        .environmentObject(onboardingViewModel)
                case .venmo:
                    VenmoView(userDidLogin: $mainViewModel.userDidLogin)
                        .environmentObject(onboardingViewModel)
                default:
                    EmptyView()
                }
            }
        }
    }

    private var mainView: some View {
        ZStack() {
            if selection == 0 {
                HomeView()
            } else if selection == 1 {
                SavedView()
            } else if selection == 2 {
                ChatsView()
                    .environmentObject(chatsViewModel)
            } else if selection == 3 {
                ProfileView()
            }
        }
    }

    private var tabBarView: some View {
        HStack {
            ForEach(0..<4, id: \.self) { index in
                TabViewIcon(selectionIndex: $selection, itemIndex: index)
                    .frame(width: 28, height: 28)

                if index != 3 {
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .padding(.horizontal, 40)
        .padding(.top, 16)
        .padding(.bottom, 36)
        .frame(width: UIScreen.width)
        .background(Constants.Colors.white)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(radius: 4)
        .offset(y: 34)
        .transition(.move(edge: .bottom))
        .animation(.easeInOut, value: isHidden)
    }
}
