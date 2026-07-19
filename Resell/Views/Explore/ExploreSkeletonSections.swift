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

struct ExploreTrendingSkeleton: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text("Trending in Electronics")
                    .font(.custom("Rubik-Medium", size: 22))
                    .foregroundStyle(Constants.Colors.black)

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Constants.Colors.black)
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)

            GeometryReader { geo in
                let spacing: CGFloat = 8
                let rightWidth = (geo.size.width - spacing) / 2
                let leftWidth = geo.size.width - rightWidth - spacing
                let smallHeight = (geo.size.height - spacing) / 2

                HStack(alignment: .top, spacing: spacing) {
                    ShimmerView()
                        .frame(width: leftWidth, height: geo.size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(spacing: spacing) {
                        HStack(spacing: spacing) {
                            ShimmerView()
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            ShimmerView()
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .frame(height: smallHeight)

                        HStack(spacing: spacing) {
                            ShimmerView()
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            ShimmerView()
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .frame(height: smallHeight)
                    }
                    .frame(width: rightWidth)
                }
            }
            .frame(height: 220)
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
        }
    }
}
