//
//  BlockedUsersView.swift
//  Resell
//
//  Created by Richie Sun on 10/10/24.
//

import Kingfisher
import SwiftUI

struct BlockedUsersView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router

    @State private var didShowPopup: Bool = false

    @State private var isLoading: Bool = false

    @State private var selectedUser: User? = nil
    @State private var blockedUsers: [User] = []

    // MARK: - UI

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(blockedUsers, id: \.self.id) { user in
                    blockedUserInfoView(user: user)
                }
                .padding(.horizontal, Constants.Spacing.horizontalPadding)
                .padding(.top, 40)

                Spacer()
            }
        }
        .frame(width: UIScreen.width)
        .background(Constants.Colors.white)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Blocked Users")
                    .font(Constants.Fonts.h3)
                    .foregroundStyle(Constants.Colors.black)
            }
        }
        .emptyState(isEmpty: blockedUsers.isEmpty && !isLoading, title: "No blocked users", text: "Users you have blocked will appear here.")
        .popupModal(isPresented: $didShowPopup) {
            popupModalContent
        }
        .loadingView(isLoading: isLoading)
        .onAppear {
            getBlockedUsers()

        }
    }

    private func blockedUserInfoView(user: User) -> some View {
        HStack(alignment: .center, spacing: 12) {
            KFImage(user.photoUrl)
                .placeholder {
                    ShimmerView()
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                }
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(Circle())

            Text("\(user.givenName) \(user.familyName)")
                .font(Constants.Fonts.body1)
                .foregroundStyle(Constants.Colors.black)

            Spacer()

            Button {
                selectedUser = user
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
            Text("Unblock \(selectedUser?.givenName ?? "")?")
                .font(Constants.Fonts.h3)
                .foregroundStyle(Constants.Colors.black)
                .frame(maxWidth: 200)
                .lineLimit(1)

            Text("They will be able to message you and view your posts.")
                .font(Constants.Fonts.body2)
                .foregroundStyle(Constants.Colors.black)
                .multilineTextAlignment(.center)
                .frame(width: 250)

            Button {
                unblockUser()
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

    // MARK: - Functions

    private func getBlockedUsers() {
        Task {
            isLoading = true

            do {
                if let userID = UserSessionManager.shared.userID {
                    blockedUsers = try await NetworkManager.shared.getBlockedUsers(id: userID).users
                } else {
                    UserSessionManager.shared.logger.error("Error in BlockedUsersView: userID not found.")
                }

                isLoading = false
            } catch {
                NetworkManager.shared.logger.error("Error in BlockedUsersView: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }

    private func unblockUser() {
        Task {
            do {
                if let id = selectedUser?.id {
                    let unblocked = UnblockUser(unblocked: id)
                    let _ = try await NetworkManager.shared.unblockUser(unblocked: unblocked)
                    
                    getBlockedUsers()
                }
            } catch {
                NetworkManager.shared.logger.error("Error in BlockerUsersView: \(error.localizedDescription)")
            }
        }
    }
}
