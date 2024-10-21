//
//  LoginView.swift
//  Resell
//
//  Created by Richie Sun on 9/9/24.
//

import SwiftUI

struct LoginView: View {

    @StateObject private var viewModel = LoginViewModel()
    @Binding var userDidLogin: Bool

    var body: some View {
        NavigationStack {
            VStack {
                Image("resell")
                    .padding(.top, 180)

                Text("resell")
                    .font(Constants.Fonts.resellLogo)
                    .foregroundStyle(Constants.Colors.resellGradient)
                    .multilineTextAlignment(.center)

                Spacer()

                PurpleButton(text: "Login with NetID", horizontalPadding: 28) {
//                    viewModel.googleSignIn {
                        userDidLogin = true
//                    }
                }

                NavigationPurpleButton(text: "Login with NetID", horizontalPadding: 28, destination: SetupProfileView(userDidLogin: $userDidLogin))
                    .padding(.bottom, Constants.Spacing.horizontalPadding)
            }
            .background(LoginGradient())
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
                }
                viewModel.didPresentError = false
            }
        }
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(25)
    }
}
