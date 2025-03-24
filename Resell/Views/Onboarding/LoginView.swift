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
    @EnvironmentObject private var onboardingViewModel: SetupProfileViewModel

    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
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
                    Task {
                        let signInResult = await viewModel.googleSignIn()
                        switch signInResult {
                        case .success:
                            mainViewModel.userDidLogin = true
                        case .accountCreationNeeded:
                            router.push(.setupProfile)
                            break
                        default:
                            break
                        }

                        mainViewModel.userDidLogin = false
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
        }
        .sheet(isPresented: $viewModel.didPresentError) {
            loginSheetView
        }
        .loadingView(isLoading: viewModel.isLoading)
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
                Task {
                    viewModel.didPresentError = false
                    await viewModel.googleSignIn()
                }
            }
        }
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(25)
    }
}
