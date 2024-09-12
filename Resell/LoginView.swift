//
//  LoginView.swift
//  Resell
//
//  Created by Richie Sun on 9/9/24.
//

import SwiftUI

struct LoginView: View {

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
            ResellPurpleButton(text: "Login with NetID") {
                viewModel.googleSignIn()
            }
        }
        .background(ResellLoginGradient())
        .sheet(isPresented: $viewModel.didPresentError) {
            VStack {
                Text(viewModel.errorText)
                    .font(Constants.Fonts.h3)
                    .multilineTextAlignment(.center)
                    .frame(width: 190)
                    .padding(.top, 48)
                Spacer()
                ResellPurpleButton(text: "Try Again", horizontalPadding: 60) {
                    viewModel.googleSignIn()
                    viewModel.didPresentError = false
                }
            }
            .presentationDetents([.height(200)])
            .presentationCornerRadius(40)
            .presentationDragIndicator(.visible)
        }

    }
}

#Preview {
    LoginView()
}
