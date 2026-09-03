//
//  ExploreSections.swift
//  Resell
//
//  Created by Andrew Gao on 9/3/26.
//

import SwiftUI

// MARK: - Daily Picks

struct ExploreDailyPicksSection: View {

    @EnvironmentObject var router: Router
    @ObservedObject private var viewModel = ExploreViewModel.shared

    private let cardWidth: CGFloat = 148
    private let imageHeight: CGFloat = 148

    var body: some View {
        if viewModel.isLoadingDailyPicks && viewModel.dailyPicks.isEmpty {
            ExploreDailyPicksSkeleton()
        } else if !viewModel.dailyPicks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Daily Picks")
                        .font(Constants.Fonts.h2)
                        .foregroundStyle(Constants.Colors.black)

                    Spacer()

                    Button {
                        router.push(.dailyPicks)
                    } label: {
                        SeeMoreLabel()
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Constants.Spacing.horizontalPadding)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(viewModel.dailyPicks) { post in
                            dailyPickCard(post)
                        }
                    }
                    .padding(.horizontal, Constants.Spacing.horizontalPadding)
                }
            }
        }
    }

    private func dailyPickCard(_ post: Post) -> some View {
        Button {
            router.push(.productDetails(post))
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ExplorePostThumbnail(urlString: post.images.first)
                    .frame(width: cardWidth, height: imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(post.title)
                    .font(Constants.Fonts.title3)
                    .foregroundStyle(Constants.Colors.black)
                    .lineLimit(1)
                    .frame(width: cardWidth, alignment: .leading)

                Text("$\(post.originalPrice)")
                    .font(Constants.Fonts.subtitle1)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .lineLimit(1)
            }
            .frame(width: cardWidth, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

struct ExploreDailyPicksSkeleton: View {

    private let cardWidth: CGFloat = 148
    private let imageHeight: CGFloat = 148

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Picks")
                    .font(Constants.Fonts.h2)
                    .foregroundStyle(Constants.Colors.black)

                Spacer()

                SeeMoreLabel()
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(0..<4, id: \.self) { _ in
                        pickCard
                    }
                }
                .padding(.horizontal, Constants.Spacing.horizontalPadding)
            }
        }
    }

    private var pickCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            ShimmerView()
                .frame(width: cardWidth, height: imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.25))
                .frame(width: cardWidth * 0.85, height: 12)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.18))
                .frame(width: cardWidth * 0.45, height: 10)
        }
        .frame(width: cardWidth, alignment: .leading)
    }
}

// MARK: - Trending

struct ExploreTrendingSection: View {

    @EnvironmentObject var router: Router
    @ObservedObject private var viewModel = ExploreViewModel.shared

    private let cardWidth: CGFloat = 148
    private let imageHeight: CGFloat = 148

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            categoryHeader

            if viewModel.isLoadingTrending && viewModel.trendingPosts.isEmpty {
                loadingCards
            } else if viewModel.trendingPosts.isEmpty {
                Text("No posts found")
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Constants.Colors.wash)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, Constants.Spacing.horizontalPadding)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(viewModel.trendingPosts) { post in
                            trendingCard(post)
                        }
                    }
                    .padding(.horizontal, Constants.Spacing.horizontalPadding)
                }
            }
        }
    }

    private var categoryHeader: some View {
        HStack(spacing: 12) {
            Menu {
                ForEach(viewModel.trendingCategories, id: \.id) { category in
                    Button {
                        viewModel.selectTrendingCategory(category)
                    } label: {
                        if category.id == viewModel.selectedTrendingCategory.id {
                            Label(category.title, systemImage: "checkmark")
                        } else {
                            Text(category.title)
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text("Trending in \(viewModel.selectedTrendingCategory.title)")
                        .font(Constants.Fonts.h2)
                        .foregroundStyle(Constants.Colors.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .allowsTightening(true)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Constants.Colors.black)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)

            Button {
                router.push(.trending(viewModel.selectedTrendingCategory))
            } label: {
                SeeMoreLabel()
            }
            .buttonStyle(.plain)
            .fixedSize()
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
    }

    private func trendingCard(_ post: Post) -> some View {
        Button {
            router.push(.productDetails(post))
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ExplorePostThumbnail(urlString: post.images.first)
                    .frame(width: cardWidth, height: imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(post.title)
                    .font(Constants.Fonts.title3)
                    .foregroundStyle(Constants.Colors.black)
                    .lineLimit(1)
                    .frame(width: cardWidth, alignment: .leading)

                HStack(spacing: 6) {
                    Text("$\(post.originalPrice)")
                        .font(Constants.Fonts.subtitle1)
                        .foregroundStyle(Constants.Colors.secondaryGray)

                    Spacer()

                    Text("\(post.displaySaveCount) \(post.displaySaveCount == 1 ? "save" : "saves")")
                        .font(Constants.Fonts.subtitle1)
                        .foregroundStyle(Constants.Colors.secondaryGray)
                }
                .frame(width: cardWidth)
            }
            .frame(width: cardWidth, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private var loadingCards: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 8) {
                        ShimmerView()
                            .frame(width: cardWidth, height: imageHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.25))
                            .frame(width: cardWidth * 0.85, height: 12)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.18))
                            .frame(width: cardWidth * 0.55, height: 10)
                    }
                }
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
        }
    }
}

// MARK: - Shared helpers

/// Outlined "See More" pill shared by every Explore section header.
private struct SeeMoreLabel: View {
    var body: some View {
        Text("See More")
            .font(Constants.Fonts.title4)
            .foregroundStyle(Constants.Colors.secondaryGray)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Constants.Colors.stroke, lineWidth: 1)
            )
    }
}

private struct ExplorePostThumbnail: View {

    let urlString: String?
    @State private var isLoaded = false

    var body: some View {
        CachedImageView(
            isImageLoaded: $isLoaded,
            imageURL: URL(string: urlString ?? "")
        )
        .clipped()
    }
}

