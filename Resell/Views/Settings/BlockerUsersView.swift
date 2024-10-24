//
//  BlockerUsersView.swift
//  Resell
//
//  Created by Richie Sun on 10/10/24.
//

import SwiftUI

struct BlockerUsersView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    
    // TODO: Replace wtih backend type
    @State private var selectedUser: String = ""
    @State private var didShowPopup: Bool = false

    // TODO: Replace dummy data
    private let userData = [
        ("justin", "Justin Guo", 0),
        ("justin", "Justin Guo", 1),
        ("justin", "Justin Guo", 2),
        ("justin", "Justin Guo", 3),
        ("justin", "Justin Guo", 4),
        ("justin", "Justin Guo", 5),
        ("justin", "Justin Guo", 6),
        ("justin", "Justin Guo", 7),
        ("justin", "Justin Guo", 8),
        ("justin", "Justin Guo", 9),
        ("justin", "Justin Guo", 10),
        ("justin", "Justin Guo", 11),
        ("justin", "Justin Guo", 12),
        ("justin", "Justin Guo", 13),
    ]

    // MARK: - UI

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(userData, id: \.self.2) { user in
                    blockerUserInfoView(user: user)
                }
            }
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .padding(.top, 24)
        .padding(.bottom, 40)
        .background(Constants.Colors.white)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Blocker Users")
                    .font(Constants.Fonts.h3)
            }
        }
        .popupModal(isPresented: $didShowPopup) {
            popupModalContent
        }
    }

    private func blockerUserInfoView(user: (String, String, Int)) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(user.0)
                .resizable()
                .frame(width: 52, height: 52)
                .clipShape(.circle)

            Text(user.1)
                .font(Constants.Fonts.body1)

            Spacer()

            Button {
                selectedUser = user.1
                withAnimation {
                    didShowPopup = true
                }
            } label: {
                Text("Unblock")
                    .font(Constants.Fonts.body1)
                    .foregroundStyle(Constants.Colors.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Constants.Colors.resellPurple)
                    .clipShape(.capsule)
            }
        }
    }

    private var popupModalContent: some View {
        VStack(spacing: 24) {
            Text("Unblock \(selectedUser)?")
                .font(Constants.Fonts.h3)
                .frame(maxWidth: 200)
                .lineLimit(1)

            Text("They will be able to message you and view your posts.")
                .font(Constants.Fonts.body2)
                .multilineTextAlignment(.center)
                .frame(width: 250)

            Button {
                // TODO: Unblock Account Backend Call
                withAnimation {
                    didShowPopup = false
                }
            } label: {
                Text("Unblock")
                    .font(Constants.Fonts.body1)
                    .foregroundStyle(Constants.Colors.errorRed)
                    .padding(.horizontal, 100)
                    .padding(.vertical, 14)
                    .overlay {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Constants.Colors.errorRed, lineWidth: 1.5)
                    }
            }

            Button {
                withAnimation {
                    didShowPopup = false
                }
            } label: {
                Text("Cancel")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.secondaryGray)
            }
        }
        .padding(Constants.Spacing.horizontalPadding)
    }
}
