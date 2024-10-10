//
//  VenmoView.swift
//  Resell
//
//  Created by Richie Sun on 9/16/24.
//

import SwiftUI

struct VenmoView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State var venmoHandle: String = ""
    @Binding var userDidLogin: Bool

    // MARK: - UI

    var body: some View {
        NavigationStack {
            VStack(alignment: .center) {
                Text("Your Venmo handle will only be visible to people interested in buying your listing.")
                    .font(Constants.Fonts.body1)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .padding(.top, 24)

                LabeledTextField(label: "Venmo Handle", text: $venmoHandle)
                    .padding(.top, 46)

                Spacer()

                PurpleButton(isActive: !venmoHandle.cleaned().isEmpty,text: "Continue") {
                    withAnimation {
                        userDidLogin = true
                    }
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
        .endEditingOnTap()
    }
}
