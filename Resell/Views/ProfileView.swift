//
//  ProfileView.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import SwiftUI

struct ProfileView: View {

    // MARK: - Properties

    @StateObject private var viewModel = ProfileViewModel()

    // MARK: - UI

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                profileImageView
                    .padding(.bottom, 12)

                Text(viewModel.user?.username ?? "")
                    .font(Constants.Fonts.h3)
                    .foregroundStyle(Constants.Colors.black)
                    .padding(.bottom, 4)

                Text(viewModel.user?.name ?? "")
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .padding(.bottom, 16)

                Text(viewModel.user?.bio ?? "")
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.black)
                    .padding(.bottom, 28)

                profileTabsView
                    .padding(.bottom, 24)

                ProductsGalleryView(items: Constants.dummyItemsData)
                    .overlay(alignment: .bottomTrailing) {
                        ExpandableAddButton()
                            .padding(.trailing, Constants.Spacing.horizontalPadding)
                            .padding(.bottom, Constants.Spacing.horizontalPadding)
                    }
            }
            .background(Constants.Colors.white)

        }
        .onChange(of: viewModel.selectedTab) { _ in
            viewModel.updateItemsGallery()
        }
    }

    private var profileImageView: some View {
        ZStack(alignment: .top) {
            HStack {
                NavigationLink {
                    SettingsView(isAccountSettings: false)
                } label: {
                    Icon(image: "settings")
                }

                Spacer()

                Button(action: {
                    // TODO: Implement Search
                }, label: {
                    Icon(image: "search")
                })
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)

            Image(viewModel.user?.profile ?? "justin")
                .resizable()
                .frame(width: 90, height: 90)
                .clipShape(.circle)
        }

    }

    private var profileTabsView: some View {
        HStack(spacing: 0) {
            tabButton(for: .listing)
            tabButton(for: .archive)
            tabButton(for: .wishlist)
        }
        .padding()
    }

    private func tabButton(for tab: ProfileViewModel.Tab) -> some View {
        VStack {
            Icon(image: tab.rawValue)
                .foregroundStyle(viewModel.selectedTab == tab ? Constants.Colors.black : Constants.Colors.inactiveGray)

            Rectangle()
                .foregroundStyle(viewModel.selectedTab == tab ? Constants.Colors.black : Constants.Colors.inactiveGray)
                .frame(width: UIScreen.width / 3, height: 1)
        }
        .background(Constants.Colors.white)
        .onTapGesture {
            viewModel.selectedTab = tab
        }
    }
    
}

#Preview {
    ProfileView()
}
