//
//  LoginView.swift
//  Resell
//
//  Created by Richie Sun on 9/9/24.
//

import SwiftUI

struct LoginView: View {

    @EnvironmentObject var router: Router
    @EnvironmentObject private var mainViewModel: MainViewModel

    @StateObject private var viewModel = LoginViewModel()
    @StateObject private var onboardingViewModel = SetupProfileViewModel()
    @Binding var userDidLogin: Bool

    var body: some View {
        NavigationStack(path: $router.path) {
            VStack {
                Image("resell")
                    .padding(.top, 180)

                Text("resell")
                    .font(Constants.Fonts.resellLogo)
                    .foregroundStyle(Constants.Colors.resellGradient)
                    .multilineTextAlignment(.center)

                Spacer()

                if !mainViewModel.hidesSignInButton {
                    PurpleButton(text: "Login with NetID", horizontalPadding: 28) {
                        viewModel.googleSignIn {
                            userDidLogin = true
                        } failure: { netid, givenName, familyName, email, googleId in
                            userDidLogin = false
                            router.push(.setupProfile(netid: netid, givenName: givenName, familyName: familyName, email: email, googleId: googleId))
                        }

                    }
                } else {
                    Image("appdev")
                        .padding(.bottom, 24)
                }
            }
            .background(LoginGradient())
            .onAppear {
                onboardingViewModel.clear()
                FirebaseNotificationService.shared.setupFCMToken()
            }
            .navigationDestination(for: Router.Route.self) { route in
                switch route {
                case .setupProfile(let netid, let givenName, let familyName, let email, let googleId):
                    SetupProfileView(userDidLogin: $userDidLogin, netid: netid, givenName: givenName, familyName: familyName, email: email, googleID: googleId)
                        .environmentObject(onboardingViewModel)
                case .venmo:
                    VenmoView(userDidLogin: $userDidLogin)
                        .environmentObject(onboardingViewModel)
                default:
                    EmptyView()
                }
            }
        }
        .sheet(isPresented: $viewModel.didPresentError) {
            loginSheetView
        }
    }

    private var loginSheetView: some View {
        VStack {
            Text(viewModel.errorText)
                .font(Constants.Fonts.h3)
                .multilineTextAlignment(.center)
                .frame(width: 190)
                .padding(.top, 48)

            Spacer()

            PurpleButton(text: "Try Again", horizontalPadding: 60) {
                viewModel.googleSignIn {
                    userDidLogin = true
                } failure: { netid, givenName, familyName, email, googleId in
                    userDidLogin = false
                    router.push(.setupProfile(netid: netid, givenName: givenName, familyName: familyName, email: email, googleId: googleId))
                }
                viewModel.didPresentError = false
            }
        }
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(25)
    }
}
