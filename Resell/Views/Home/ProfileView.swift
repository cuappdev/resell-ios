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
                .lineLimit(3)

            profileTabsView

            if viewModel.selectedTab == .wishlist {
                requestsView
                    .emptyState(isEmpty: viewModel.requests.isEmpty, title: "No active requests", text: "Submit a request and get notified when someone lists something similar")
            } else {
                ProductsGalleryView(items: viewModel.selectedPosts)
                    .emptyState(isEmpty: viewModel.selectedPosts.isEmpty && !viewModel.isLoading, title: viewModel.selectedTab == .listing ? "No listings posted" : "No items archived", text: viewModel.selectedTab == .listing ? "When you post a listing, it will be displayed here" : "When a listing is sold or archived, it will be displayed here")
                    .padding(.top, 24)
                    .loadingView(isLoading: viewModel.isLoading)
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
                    router.push(.search(viewModel.user?.firebaseUid))
                } label: {
                    Icon(image: "search")
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            ExpandableAddButton()
                .padding(.bottom, 40)
        }
        .onChange(of: viewModel.selectedTab) { _ in
            viewModel.updateItemsGallery()
        }
        .onAppear {
            viewModel.getUser()
        }
        .refreshable {
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

    private var requestsView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.requests, id: \.self.id) { request in
                    SwipeableRow {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(request.title)
                                    .font(Constants.Fonts.title2)
                                    .foregroundStyle(Constants.Colors.black)
                                    .multilineTextAlignment(.leading)

                                Text(request.description)
                                    .font(Constants.Fonts.body2)
                                    .foregroundStyle(Constants.Colors.black)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 12)
                        .background(Constants.Colors.white)
                        .clipShape(.rect(cornerRadius: 15))
                        .overlay {
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Constants.Colors.stroke, lineWidth: 1)
                        }
                    } onDelete: {
                        viewModel.deleteRequest(id: request.id)
                        viewModel.requests.removeAll { $0.id == request.id }
                    }
                }
            }
            .padding(Constants.Spacing.horizontalPadding)
        }
        .background(Constants.Colors.white)
    }
}
