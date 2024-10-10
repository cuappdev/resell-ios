//
//  BlockerUsersView.swift
//  Resell
//
//  Created by Richie Sun on 10/10/24.
//

import SwiftUI

struct BlockerUsersView: View {

    // MARK: - Properties

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
                    HStack(alignment: .center, spacing: 12) {
                        Image(user.0)
                            .resizable()
                            .frame(width: 52, height: 52)
                            .clipShape(.circle)

                        Text(user.1)
                            .font(Constants.Fonts.body1)

                        Spacer()

                        Button {
                            // TODO: Unblock Backend Call
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
    }
}
