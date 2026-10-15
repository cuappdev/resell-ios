//
//  EventSpaceView.swift
//  Resell
//
//  Created by Andrew Gao on 10/11/26.
//

import SwiftUI

/// Feed of the listings tagged for one event, opened from Explore's Event Spaces row.
/// The event's photo heads the screen, with the feed on a rounded sheet over it.
struct EventSpaceView: View {

    // MARK: - Properties

    let event: EventSpace

    @StateObject private var viewModel: EventSpaceViewModel

    init(event: EventSpace) {
        self.event = event
        _viewModel = StateObject(wrappedValue: EventSpaceViewModel(event: event))
    }

    /// Width over height of the banner photos (414×231).
    private let bannerAspectRatio: CGFloat = 414 / 231
    private let bannerTintOpacity: CGFloat = 0.3
    /// How far the rounded feed sheet overlaps the banner.
    private let sheetOverlap: CGFloat = 20
    private let sheetCornerRadius: CGFloat = 18
    private let sheetTopPadding: CGFloat = 20
    private let sheetTitleSpacing: CGFloat = 20

    // MARK: - UI

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                banner

                feedSheet
                    .padding(.top, -sheetOverlap)
            }
        }
        .background(Constants.Colors.white)
        .ignoresSafeArea(edges: .top)
        .refreshable {
            await viewModel.loadPosts(forceRefresh: true)
        }
        .task {
            await viewModel.loadPosts()
        }
        .navigationBarBackButtonHidden(true)
        .enableSwipeBack()
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton(tint: Constants.Colors.white)
            }
        }
    }

    private var banner: some View {
        Color.clear
            .aspectRatio(bannerAspectRatio, contentMode: .fit)
            .background {
                bannerPhoto
            }
            .overlay(alignment: .bottomLeading) {
                Text(event.title)
                    .font(Constants.Fonts.h1)
                    .foregroundStyle(Constants.Colors.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, Constants.Spacing.horizontalPadding)
                    .padding(.bottom, sheetOverlap + Constants.Spacing.spacing12)
            }
    }

    /// Grows upward from its bottom edge as the feed is pulled down, so the
    /// photo keeps covering the gap above it.
    private var bannerPhoto: some View {
        GeometryReader { proxy in
            let pullDistance = max(0, proxy.frame(in: .global).minY)

            Image(event.bannerImageName)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height + pullDistance)
                .overlay(Constants.Colors.black.opacity(bannerTintOpacity))
                .clipped()
                .offset(y: -pullDistance)
        }
    }

    private var feedSheet: some View {
        VStack(alignment: .leading, spacing: sheetTitleSpacing) {
            Text("Shop by Item")
                .font(Constants.Fonts.h2)
                .foregroundStyle(Constants.Colors.black)
                .padding(.horizontal, Constants.Spacing.horizontalPadding)

            feed
        }
        .padding(.top, sheetTopPadding)
        // At least a screen tall so the banner can scroll away even when the
        // event has only a few listings.
        .frame(maxWidth: .infinity, minHeight: UIScreen.height, alignment: .topLeading)
        .background(Constants.Colors.white)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: sheetCornerRadius,
                topTrailingRadius: sheetCornerRadius
            )
        )
    }

    private var feed: some View {
        ProductsGalleryView(
            items: viewModel.posts,
            onScrollToBottom: viewModel.fetchMorePosts
        )
        .loadingView(isLoading: viewModel.isLoading)
        .emptyState(
            isEmpty: viewModel.posts.isEmpty && !viewModel.isLoading,
            title: "No \(event.title) listings yet",
            text: "Listings tagged for this event will be displayed here."
        )
        .frame(maxWidth: .infinity)
    }
}
