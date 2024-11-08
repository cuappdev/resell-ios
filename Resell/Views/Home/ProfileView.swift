//
//  ProfileView.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import Kingfisher
import SwiftUI

struct ProfileView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    @StateObject private var viewModel = ProfileViewModel()

    // MARK: - UI

    var body: some View {
        NavigationStack(path: $router.path) {
            VStack(spacing: 0) {
                profileImageView
                    .padding(.bottom, 12)

                Text(viewModel.user?.username ?? "")
                    .font(Constants.Fonts.h3)
                    .foregroundStyle(Constants.Colors.black)
                    .padding(.bottom, 4)

                Text(viewModel.user?.givenName ?? "")
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .padding(.bottom, 16)

                Text(viewModel.user?.bio ?? "")
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.black)
                    .padding(.bottom, 28)

                profileTabsView

                if viewModel.selectedTab == .wishlist {

                } else {
                    ProductsGalleryView(items: viewModel.selectedPosts)
                        .emptyState(isEmpty: $viewModel.selectedPosts.isEmpty, title: viewModel.selectedTab == .listing ? "No listings posted" : "No items archived", text: viewModel.selectedTab == .listing ? "When you post a listing, it will be displayed here" : "When a listing is sold or archived, it will be displayed here")
                }
            }
            .background(Constants.Colors.white)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        router.push(.settings(false))
                    } label: {
                        Icon(image: "settings")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // TODO: Implement Search
                    } label: {
                        Icon(image: "search")
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                ExpandableAddButton()
                    .padding(.bottom, 40)
            }
        }
        .onChange(of: viewModel.selectedTab) { _ in
            viewModel.updateItemsGallery()
        }
        .onAppear {
            viewModel.getUser()
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

    private var profileTabsView: some View {
        HStack(spacing: 0) {
            tabButton(for: .listing)
            tabButton(for: .archive)
            tabButton(for: .wishlist)
        }
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
