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
            Spacer()
            ResellPurpleButton(text: "Login with NetID") {
                viewModel.googleSignIn()
            }
        }
        .background(ResellLoginGradient())
    }
}

#Preview {
    LoginView()
}
