//
//  ExploreView.swift
//  Resell
//

import SwiftUI

struct ExploreView: View {

    @EnvironmentObject var router: Router
    @ObservedObject private var homeViewModel = HomeViewModel.shared
    @ObservedObject private var recentlyViewed = RecentlyViewedViewModel.shared
    @ObservedObject private var exploreViewModel = ExploreViewModel.shared

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 28) {
//                ExploreEventsSkeleton()

                CategoriesView()

                justForYouSection

                ExploreDailyPicksSection()

                ExploreTrendingSection()
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Constants.Colors.white)
        .navigationBarBackButtonHidden()
        .onAppear {
            Task {
                async let saved: () = homeViewModel.getSavedPosts()
                async let recent: () = recentlyViewed.loadPreviewPosts()
                async let explore: () = exploreViewModel.loadAll()
                await saved
                await recent
                await explore
            }
        }
        .refreshable {
            async let saved: () = homeViewModel.getSavedPosts(forceRefresh: true)
            async let recent: () = recentlyViewed.loadPreviewPosts(forceRefresh: true)
            async let explore: () = exploreViewModel.loadAll(forceRefresh: true)
            await saved
            await recent
            await explore
        }
    }

    private var justForYouSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Just For You")
                .font(.custom("Rubik-Medium", size: 22))
                .foregroundStyle(Constants.Colors.black)
                .padding(.horizontal, Constants.Spacing.horizontalPadding)

            if homeViewModel.savedItems.isEmpty && recentlyViewed.posts.isEmpty {
                emptyJustForYou
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        if !homeViewModel.savedItems.isEmpty {
                            ExploreCollageCard(
                                title: "Saved",
                                subtitle: "\(homeViewModel.savedItems.count)",
                                posts: homeViewModel.savedItems
                            ) {
                                router.push(.saved)
                            }
                            .frame(width: collageCardWidth)
                        }

                        if !recentlyViewed.posts.isEmpty {
                            ExploreCollageCard(
                                title: "Recently Viewed",
                                subtitle: nil,
                                posts: recentlyViewed.posts
                            ) {
                                router.push(.recentlyViewed)
                            }
                            .frame(width: collageCardWidth)
                        }
                    }
                    .padding(.horizontal, Constants.Spacing.horizontalPadding)
                }
            }
        }
    }

    private var emptyJustForYou: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Constants.Colors.stroke, lineWidth: 1)

            VStack(spacing: 6) {
                Text("Nothing here yet")
                    .font(Constants.Fonts.title2)
                    .foregroundStyle(Constants.Colors.black)
                Text("Save listings or browse products to fill this section.")
                    .font(Constants.Fonts.subtitle1)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .frame(height: 110)
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
    }

    private var collageCardWidth: CGFloat {
        let horizontalPadding = Constants.Spacing.horizontalPadding * 2
        let spacing: CGFloat = 12
        // A bit wider than half-screen so the pair peeks into horizontal scroll.
        return (UIScreen.main.bounds.width - horizontalPadding - spacing) / 2 + 14
    }
}
