//
//  ExploreSections.swift
//  Resell
//
//  Created by Andrew Gao on 9/3/26.
//

import SwiftUI

// MARK: - Daily Picks

/// Explore's Daily Picks rail, with a See More link to the full list.
struct ExploreDailyPicksSection: View {

    @EnvironmentObject private var router: Router
    @ObservedObject private var viewModel = ExploreViewModel.shared

    var body: some View {
        if viewModel.isLoadingDailyPicks && viewModel.dailyPicks.isEmpty {
            ExploreDailyPicksSkeleton()
        } else if !viewModel.dailyPicks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                ExploreSectionHeader(title: "Daily Picks") {
                    router.push(.dailyPicks)
                }

                ExploreRail {
                    ForEach(viewModel.dailyPicks) { post in
                        ExplorePostCard(post: post) {
                            router.push(.productDetails(post))
                        }
                    }
                }
            }
        }
    }
}

/// Placeholder for `ExploreDailyPicksSection` while its first load is in flight.
private struct ExploreDailyPicksSkeleton: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ExploreSectionHeader(title: "Daily Picks")

            ExploreRailSkeleton(detailWidthRatio: 0.45)
        }
    }
}

// MARK: - Trending

/// Explore's Trending rail, with a menu to switch categories and a See More link.
struct ExploreTrendingSection: View {

    @EnvironmentObject private var router: Router
    @ObservedObject private var viewModel = ExploreViewModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            categoryHeader

            if viewModel.isLoadingTrending && viewModel.trendingPosts.isEmpty {
                ExploreRailSkeleton(detailWidthRatio: 0.55)
            } else if viewModel.trendingPosts.isEmpty {
                emptyTrending
            } else {
                ExploreRail {
                    ForEach(viewModel.trendingPosts) { post in
                        ExplorePostCard(post: post, showsSaveCount: true) {
                            router.push(.productDetails(post))
                        }
                    }
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
                categoryMenuLabel
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

    private var categoryMenuLabel: some View {
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

    private var emptyTrending: some View {
        Text("No posts found")
            .font(Constants.Fonts.body2)
            .foregroundStyle(Constants.Colors.secondaryGray)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Constants.Colors.wash)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
    }
}

// MARK: - Shared helpers

private enum ExploreRailLayout {
    static let cardWidth: CGFloat = 148
    static let imageHeight: CGFloat = 148
    static let cardSpacing: CGFloat = 12
}

/// Section title with a trailing "See More" pill, which is only tappable when
/// `onSeeMore` is set.
private struct ExploreSectionHeader: View {

    let title: String
    var onSeeMore: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(Constants.Fonts.h2)
                .foregroundStyle(Constants.Colors.black)

            Spacer()

            if let onSeeMore {
                Button(action: onSeeMore) {
                    SeeMoreLabel()
                }
                .buttonStyle(.plain)
            } else {
                SeeMoreLabel()
            }
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
    }
}

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

/// Horizontally scrolling row of cards, inset to line up with the section header.
private struct ExploreRail<Content: View>: View {

    @ViewBuilder let content: Content

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: ExploreRailLayout.cardSpacing) {
                content
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
        }
    }
}

/// Square-thumbnail listing card used by the Explore rails.
private struct ExplorePostCard: View {

    let post: Post
    /// Shows the listing's save count opposite its price.
    var showsSaveCount: Bool = false
    let action: () -> Void

    private var saveCountLabel: String {
        "\(post.displaySaveCount) \(post.displaySaveCount == 1 ? "save" : "saves")"
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ExplorePostThumbnail(urlString: post.images.first)
                    .frame(width: ExploreRailLayout.cardWidth, height: ExploreRailLayout.imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(post.title)
                    .font(Constants.Fonts.title3)
                    .foregroundStyle(Constants.Colors.black)
                    .lineLimit(1)
                    .frame(width: ExploreRailLayout.cardWidth, alignment: .leading)

                detailRow
            }
            .frame(width: ExploreRailLayout.cardWidth, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var detailRow: some View {
        if showsSaveCount {
            HStack(spacing: 6) {
                detailLabel("$\(post.originalPrice)")

                Spacer()

                detailLabel(saveCountLabel)
            }
            .frame(width: ExploreRailLayout.cardWidth)
        } else {
            detailLabel("$\(post.originalPrice)")
        }
    }

    private func detailLabel(_ text: String) -> some View {
        Text(text)
            .font(Constants.Fonts.subtitle1)
            .foregroundStyle(Constants.Colors.secondaryGray)
            .lineLimit(1)
    }
}

/// Shimmering stand-in for a rail of `ExplorePostCard`s.
private struct ExploreRailSkeleton: View {

    /// Width of the second placeholder line, as a fraction of the card width.
    let detailWidthRatio: CGFloat

    private let placeholderCount = 4

    var body: some View {
        ExploreRail {
            ForEach(0..<placeholderCount, id: \.self) { _ in
                cardSkeleton
            }
        }
    }

    private var cardSkeleton: some View {
        VStack(alignment: .leading, spacing: 8) {
            ShimmerView()
                .frame(width: ExploreRailLayout.cardWidth, height: ExploreRailLayout.imageHeight)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.25))
                .frame(width: ExploreRailLayout.cardWidth * 0.85, height: 12)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.18))
                .frame(width: ExploreRailLayout.cardWidth * detailWidthRatio, height: 10)
        }
        .frame(width: ExploreRailLayout.cardWidth, alignment: .leading)
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
