//
//  HomeView.swift
//  Resell
//
//  Created by Richie Sun on 9/11/24.
//

import Kingfisher
import OAuth2
import SwiftUI
import UIKit

struct HomeView: View {

    @EnvironmentObject private var mainViewModel: MainViewModel
    @EnvironmentObject private var searchViewModel: SearchViewModel
    @EnvironmentObject var router: Router

    @ObservedObject private var viewModel = HomeViewModel.shared
    @StateObject private var filtersViewModel = FiltersViewModel(isHome: true)

    @FocusState private var searchFocused: Bool

    @State private var isSearchExpanded: Bool = false
    @State private var searchText: String = ""
    @State private var presentPopup = false
    @State private var showFilterInToolbar: Bool = false

    /// How far content must scroll before the inline filter is considered off-screen.
    private let inlineFilterHideOffset: CGFloat = 48
    private let toolbarControlHeight: CGFloat = 40

    /// True while the search card covers the feed with nothing searched yet —
    /// the feed underneath should not scroll behind it. Once results are on
    /// screen the scroll view owns them and has to stay scrollable.
    private var isSearchPanelBlocking: Bool {
        isSearchExpanded && searchViewModel.isSearching
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: !isSearchPanelBlocking) {
            if isSearchExpanded && !searchViewModel.isSearching {
                searchResultsContent
                    .padding(.top, 12)
            } else {
                homeFeedContent
                    .padding(.top, 12)
                    .background {
                        // Sits inside the scroll content so it can walk up to the
                        // enclosing UIScrollView. PreferenceKeys and GeometryReader
                        // stall mid-scroll, which left the toolbar filter stuck.
                        HomeScrollOffsetReader { offsetY in
                            updateFilterToolbarVisibility(offsetY > inlineFilterHideOffset)
                        }
                    }
            }
        }
        .scrollDisabled(isSearchPanelBlocking)
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 44)
        }
        .overlay(alignment: .top) {
            customToolbar
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: isSearchExpanded) { isExpanded in
            if isExpanded {
                updateFilterToolbarVisibility(false)
                searchViewModel.isSearching = true
                // Focus after the panel paints — creating the field and raising
                // the keyboard in one frame drops the first animation.
                Task { @MainActor in
                    await Task.yield()
                    searchFocused = true
                }
            } else {
                searchText = ""
                searchViewModel.isSearching = true
                searchViewModel.searchedItems = []
                searchFocused = false
            }
        }
        .onChange(of: searchFocused) { focused in
            if focused { searchViewModel.isSearching = true }
        }
        .onAppear {
            if !viewModel.isFilteredFeed {
                viewModel.getAllPosts()
            }
            viewModel.getBlockedUsers()
            Task { await viewModel.getSavedPosts() }
            withAnimation { mainViewModel.hidesTabBar = false }
        }
        .onDisappear {
            viewModel.cleanupMemory()
        }
        .background(Constants.Colors.white)
        .refreshable {
            if viewModel.isFilteredFeed {
                Task { try? await filtersViewModel.applyFilters(homeViewModel: viewModel) }
            } else {
                viewModel.getAllPosts(forceRefresh: true)
            }
        }
        .loadingView(isLoading: viewModel.isLoading)
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $presentPopup) {
            FilterView(home: true, isPresented: $presentPopup)
                .environmentObject(filtersViewModel)
        }
    }

    // MARK: - Feed Content

    private var homeFeedContent: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Recent Listings")
                    .font(Constants.Fonts.h2)
                    .foregroundStyle(Constants.Colors.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 24)

                Button {
                    presentPopup = true
                } label: {
                    Image("filters")
                        .resizable()
                        .frame(width: 24, height: 21)
                        .padding(12)
                        .contentShape(Rectangle())
                }
                .padding(.trailing, 12)
            }
            .padding(.bottom, 4)

            ProductsGalleryView(items: viewModel.filteredItems, onScrollToBottom: viewModel.fetchMoreItems)
        }
    }

    @ViewBuilder
    private var searchResultsContent: some View {
        if searchViewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 80)
        } else if searchViewModel.searchedItems.isEmpty {
            VStack(spacing: 12) {
                Text("No results")
                    .font(Constants.Fonts.h2)
                    .foregroundStyle(Constants.Colors.black)

                Text("Try a different search term")
                    .font(Constants.Fonts.body1)
                    .foregroundStyle(Constants.Colors.secondaryGray)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
        } else {
            ProductsGalleryView(items: searchViewModel.searchedItems)
        }
    }

    // MARK: - Custom Toolbar

    @ViewBuilder
    private var customToolbar: some View {
        if isSearchExpanded {
            SearchPanel(
                placeholder: "What are you looking for?",
                text: $searchText,
                history: Array(mainViewModel.searchHistory.prefix(5)),
                showsHistory: searchViewModel.isSearching,
                isFocused: $searchFocused,
                onSubmit: runSearch,
                onDismiss: {
                    withAnimation(.snappy(duration: 0.2)) { isSearchExpanded = false }
                }
            )
        } else {
            HStack(spacing: 10) {
                // The inline filter button scrolls away with the section header;
                // this is where it goes so it stays reachable.
                if showFilterInToolbar {
                    floatingFilterButton
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }

                searchPill

                notificationsButton
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
            .frame(height: toolbarControlHeight)
            .animation(.easeInOut(duration: 0.2), value: showFilterInToolbar)
        }
    }

    private var searchPill: some View {
        Button {
            isSearchExpanded = true
        } label: {
            HStack(spacing: 8) {
                Image("search")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)

                Text("What are you looking for?")
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .frame(height: toolbarControlHeight)
        .modifier(GlassToolbarModifier())
    }

    private var notificationsButton: some View {
        Button {
            router.push(.notifications)
        } label: {
            Image(systemName: "bell")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Constants.Colors.black)
                .frame(width: 18, height: 18)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .frame(width: toolbarControlHeight, height: toolbarControlHeight)
        .modifier(GlassToolbarModifier())
        .accessibilityLabel("Notifications")
    }

    private var floatingFilterButton: some View {
        Button {
            presentPopup = true
        } label: {
            Image("filters")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .frame(width: toolbarControlHeight, height: toolbarControlHeight)
        .modifier(GlassToolbarModifier())
        .accessibilityLabel("Filters")
    }

    // MARK: - Helpers

    private func updateFilterToolbarVisibility(_ shouldShow: Bool) {
        guard shouldShow != showFilterInToolbar else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            showFilterInToolbar = shouldShow
        }
    }

    private func runSearch(_ query: String) {
        guard !query.isEmpty else { return }
        searchFocused = false
        searchViewModel.searchItems(
            with: query,
            userID: nil,
            saveQuery: true,
            mainViewModel: mainViewModel
        ) {}
    }
}

/// Reports the enclosing `UIScrollView`'s vertical content offset.
///
/// Must be placed *inside* the scroll content: it finds the scroll view by
/// walking up its own superview chain.
private struct HomeScrollOffsetReader: UIViewRepresentable {

    var onChange: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onChange: onChange)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onChange = onChange
        context.coordinator.attach(from: uiView)
    }

    final class Coordinator {

        var onChange: (CGFloat) -> Void
        private weak var scrollView: UIScrollView?
        private var observation: NSKeyValueObservation?

        init(onChange: @escaping (CGFloat) -> Void) {
            self.onChange = onChange
        }

        func attach(from view: UIView) {
            guard scrollView == nil else { return }
            // Retry across a few runloop turns: on the first update pass the
            // SwiftUI ScrollView host isn't in the hierarchy yet.
            attemptAttach(from: view, remainingAttempts: 8)
        }

        private func attemptAttach(from view: UIView, remainingAttempts: Int) {
            if let enclosing = view.enclosingScrollView() {
                scrollView = enclosing
                observation = enclosing.observe(\.contentOffset, options: [.initial, .new]) { [weak self] scrollView, _ in
                    let offsetY = scrollView.contentOffset.y
                    DispatchQueue.main.async {
                        self?.onChange(offsetY)
                    }
                }
                return
            }

            guard remainingAttempts > 0 else { return }
            DispatchQueue.main.async { [weak self, weak view] in
                guard let self, let view, self.scrollView == nil else { return }
                self.attemptAttach(from: view, remainingAttempts: remainingAttempts - 1)
            }
        }
    }
}

private extension UIView {
    func enclosingScrollView() -> UIScrollView? {
        var current: UIView? = self
        while let view = current {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            current = view.superview
        }
        return nil
    }
}
