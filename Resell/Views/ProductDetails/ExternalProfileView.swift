//
//  ExternalProfileView.swift
//  Resell
//
//  Created by Richie Sun on 11/16/24.
//

import Kingfisher
import SwiftUI

struct ExternalProfileView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    @StateObject private var viewModel = ProfileViewModel()

    var userID: String

    // MARK: - UI

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                profileImageView
                    .padding(.bottom, 12)
                    .padding(.horizontal, 24)

                Text(viewModel.user?.username ?? "")
                    .font(Constants.Fonts.h3)
                    .foregroundStyle(Constants.Colors.black)
                    .padding(.bottom, 4)
                    .padding(.horizontal, 24)

                Text(viewModel.user?.givenName ?? "")
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .padding(.bottom, 16)
                    .padding(.horizontal, 24)

                Text(viewModel.user?.bio ?? "")
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.black)
                    .padding(.bottom, 28)
                    .padding(.horizontal, 24)
                    .lineLimit(3)

                Divider()

                ProductsGalleryView(items: viewModel.selectedPosts)
                    .loadingView(isLoading: viewModel.isLoadingUser)
            }
            .background(Constants.Colors.white)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            router.push(.search(userID))
                        } label: {
                            Icon(image: "search")
                        }

                        Button {
                            withAnimation {
                                viewModel.didShowOptionsMenu.toggle()
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .resizable()
                                .frame(width: 24, height: 6)
                                .foregroundStyle(viewModel.sellerIsBlocked ? Constants.Colors.white : Constants.Colors.black)
                        }
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .frame(width: 18, height: 24)
                        .foregroundStyle(Constants.Colors.white)
                        .offset(x: -20)
                }
            }
            .onAppear {
                viewModel.getExternalUser(id: userID)
            }

            if viewModel.sellerIsBlocked {
                ZStack {
                    Constants.Colors.black
                        .opacity(0.75)
                        .ignoresSafeArea()

                    Text("This profile is blocked")
                        .font(Constants.Fonts.title1)
                        .foregroundStyle(Constants.Colors.white)
                }
                .animation(.easeInOut, value: viewModel.sellerIsBlocked)
            }

            if viewModel.didShowOptionsMenu {
                OptionsMenuView(showMenu: $viewModel.didShowOptionsMenu, didShowBlockView: $viewModel.didShowBlockView, options: {
                    var options: [Option] = [
                        .report(type: "User", id: userID),
                    ]
                    if viewModel.sellerIsBlocked {
                        options.append(.unblock)
                    } else {
                        options.append(.block)
                    }
                    return options
                }())
                .zIndex(1)
            }
        }
        .popupModal(isPresented: $viewModel.didShowBlockView) {
            popupModalContent
        }
        .onChange(of: viewModel.isLoading) { newValue in
            if !newValue {
                router.popToRoot()
            }
        }
    }

    private var profileImageView: some View {
        KFImage(viewModel.user?.photoUrl)
            .cacheOriginalImage()
            .placeholder {
                ShimmerView()
                    .frame(width: 90, height: 90)
            }
            .resizable()
            .frame(width: 90, height: 90)
            .clipShape(.circle)
    }

    private var popupModalContent: some View {
        VStack(spacing: 24) {
            Text("Block User")
                .font(Constants.Fonts.h3)
                .foregroundStyle(Constants.Colors.black)

            Text("Are you sure you’d like to \(viewModel.sellerIsBlocked ? "un" : "")block this user?")
                .font(Constants.Fonts.body2)
                .foregroundStyle(Constants.Colors.black)
                .multilineTextAlignment(.center)
                .frame(width: 275)

            PurpleButton(isLoading: viewModel.isLoading,text: viewModel.sellerIsBlocked ? "Unblock" : "Block", horizontalPadding: 100) {
                if viewModel.sellerIsBlocked {
                    viewModel.unblockUser(id: userID)
                } else {
                    viewModel.blockUser(id: userID)
                }
            }

            Button{
                withAnimation {
                    viewModel.didShowBlockView = false
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
