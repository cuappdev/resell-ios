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

                PurpleButton(text: "Continue") {
                    withAnimation {
                        userDidLogin = true
                    }
                }

                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton(dismiss: self.dismiss)
            }

            ToolbarItem(placement: .principal) {
                HStack {
                    Text("Link your")
                        .font(Constants.Fonts.h3)
                    Image("venmoLogo")
                }
            }
        }
    }
}
