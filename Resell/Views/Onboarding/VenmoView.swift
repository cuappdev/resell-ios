//
//  VenmoView.swift
//  Resell
//
//  Created by Richie Sun on 9/16/24.
//

import SwiftUI

struct VenmoView: View {

    // MARK: - Properties

    @EnvironmentObject private var router: Router
    @EnvironmentObject private var mainViewModel: MainViewModel
    @EnvironmentObject private var viewModel: SetupProfileViewModel
    
    @Binding var userDidLogin: Bool

    // MARK: - UI

    var body: some View {
        NavigationStack {
            VStack(alignment: .center) {
                Text("Your Venmo handle will only be visible to people interested in buying your listing.")
                    .font(Constants.Fonts.body1)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .padding(.top, 24)

                LabeledTextField(label: "Venmo Handle", text: $viewModel.venmoHandle)
                    .padding(.top, 46)

                Spacer()

                PurpleButton(isLoading: viewModel.isLoading, isActive: !viewModel.venmoHandle.cleaned().isEmpty,text: "Continue") {
                    viewModel.createNewUser()
                }

                Button(action: {
                    withAnimation {
                        userDidLogin = true
                    }
                }, label: {
                    Text("Skip")
                        .font(Constants.Fonts.title1)
                        .foregroundStyle(Constants.Colors.resellPurple)
                        .padding(.top, 14)
                })
            }
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .background(Constants.Colors.white)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Text("Link your")
                        .font(Constants.Fonts.h3)
                        .foregroundStyle(Constants.Colors.black)
                    
                    Image("venmoLogo")
                }
            }
        }
        .onChange(of: viewModel.isLoading) { newValue in
            if !newValue {
                withAnimation {
                    mainViewModel.addFCMToken()
                    router.popToRoot()
                    userDidLogin = true
                }
            }
        }
        .endEditingOnTap()
    }
}
