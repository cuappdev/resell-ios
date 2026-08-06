//
//  ExploreSkeletonSections.swift
//  Resell
//

import SwiftUI

// MARK: - Upcoming Events

struct ExploreEventsSkeleton: View {

    private let cardWidth: CGFloat = 260
    private let cardHeight: CGFloat = 170

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shop Upcoming Events")
                .font(.custom("Rubik-Medium", size: 22))
                .foregroundStyle(Constants.Colors.black)
                .padding(.horizontal, Constants.Spacing.horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        eventCard
                    }
                }
                .padding(.horizontal, Constants.Spacing.horizontalPadding)
            }
        }
    }

    private var eventCard: some View {
        ZStack(alignment: .bottomLeading) {
            ShimmerView()
                .frame(width: cardWidth, height: cardHeight)

            LinearGradient(
                colors: [Color.black.opacity(0.65), Color.clear],
                startPoint: .bottom,
                endPoint: .center
            )

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.55))
                .frame(width: 140, height: 14)
                .padding(12)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

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
                        .font(.custom("Rubik-Medium", size: 22))
                        .foregroundStyle(Constants.Colors.black)

                    Spacer()

                    Button {
                        router.push(.dailyPicks)
                    } label: {
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
                    .font(.custom("Rubik-Medium", size: 22))
                    .foregroundStyle(Constants.Colors.black)

                Spacer()

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
                        .font(.custom("Rubik-Medium", size: 22))
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
            .buttonStyle(.plain)
            .fixedSize()
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
    }

    private func trendingCard(_ post: Post) -> some View {
        Button {
            router.push(.trending(viewModel.selectedTrendingCategory))
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

                    Text("\(post.savedCount ?? post.saveCount ?? 0) saves")
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

