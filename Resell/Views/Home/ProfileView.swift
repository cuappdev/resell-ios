//
//  ProfileView.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import Kingfisher
import LucideIcons
import SwiftUI

struct ProfileView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject private var currentUser = CurrentUserProfileManager.shared

    // MARK: - UI

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                profileImageView
                    .padding(.bottom, 12)
                
                Text("@\(currentUser.username)")
                    .font(Constants.Fonts.h3)
                    .foregroundStyle(Constants.Colors.black)
                    .padding(.bottom, 4)
                
                Text(currentUser.givenName)
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .padding(.bottom, 16)
                
                Text(currentUser.bio)
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.black)
                    .padding(.bottom, 28)
                    .padding(.horizontal, 24)
                    .lineLimit(3)
                
                profileTabsView
                
                if viewModel.selectedTab == .reviews {
                    ReviewSection(reviews: currentUser.userReviews)
                        .loadingView(isLoading: viewModel.isLoading)
                } else {
                    ProductsGalleryView(items: viewModel.selectedPosts)
                        .emptyState(
                            isEmpty: viewModel.selectedPosts.isEmpty && !viewModel.isLoading,
                            title: viewModel.selectedTab == .listing ? "No listings posted" : "No items archived",
                            text: viewModel.selectedTab == .listing
                            ? "When you post a listing, it will be displayed here"
                            : "When a listing is sold or archived, it will be displayed here"
                        )
                        .padding(.top, 24)
                        .loadingView(isLoading: viewModel.isLoading)
                }
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
                    router.push(.availability)
                } label: {
                    Icon(image: "calendar-internal")
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.loadCurrentUser()
        }
        .refreshable {
            viewModel.loadCurrentUser(forceRefresh: true)
        }
    }

    private var profileImageView: some View {
        Image(uiImage: currentUser.profilePic)
            .resizable()
            .scaledToFill()
            .frame(width: 90, height: 90)
            .background(Constants.Colors.stroke)
            .clipShape(.circle)
    }

    private var profileTabsView: some View {
        HStack(spacing: 0) {
            tabButton(for: .listing)
            tabButton(for: .archive)
            tabButton(for: .reviews)
        }
    }

    private func tabButton(for tab: ProfileViewModel.Tab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedTab = tab
            }
        } label: {
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    tabIcon(for: tab)

                    Text("\(tabTitle(for: tab)) (\(tabCount(for: tab)))")
                        .font(Constants.Fonts.body2)
                        .fontWeight(.medium)
                }
                .foregroundStyle(
                    viewModel.selectedTab == tab
                        ? Constants.Colors.black
                        : Constants.Colors.inactiveGray
                )

                Rectangle()
                    .fill(
                        viewModel.selectedTab == tab
                            ? Constants.Colors.black
                            : Constants.Colors.stroke
                    )
                    .frame(height: viewModel.selectedTab == tab ? 2 : 1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func tabIcon(for tab: ProfileViewModel.Tab) -> some View {
        switch tab {
        case .listing:
            Image(uiImage: Lucide.store)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        case .archive:
            Icon(image: "archive")
        case .reviews:
            Image(systemName: "star.fill")
                .font(.system(size: 20))
        }
    }

    private func tabTitle(for tab: ProfileViewModel.Tab) -> String {
        switch tab {
        case .listing: return "Listings"
        case .archive: return "Archive"
        case .reviews: return "Reviews"
        }
    }

    private func tabCount(for tab: ProfileViewModel.Tab) -> Int {
        switch tab {
        case .listing: return currentUser.userPosts.count
        case .archive: return currentUser.archivedPosts.count
        case .reviews: return currentUser.userReviews.count
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
                    }
                }
            }
            .padding(Constants.Spacing.horizontalPadding)
        }
        .background(Constants.Colors.white)
    }
}
