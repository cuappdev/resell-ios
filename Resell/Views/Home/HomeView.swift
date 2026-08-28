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

    @State var expand: Bool = false
    @State var searchText: String = ""
    @State var forYouPosts: [[Post]] = []
    @State private var presentPopup = false
    @State private var showFilterInToolbar: Bool = false

    /// How far content must scroll before the inline filter is considered off-screen.
    private let inlineFilterHideOffset: CGFloat = 48

    var body: some View {
        ScrollView(.vertical, showsIndicators: !expand) {
            if expand && !searchViewModel.isSearching {
                searchResultsContent
                    .padding(.top, 12)
            } else {
                homeFeedContent
                    .padding(.top, 12)
                    .background {
                        // PreferenceKeys / GeometryReader often stall mid-scroll;
                        // observe the underlying UIScrollView contentOffset instead.
                        HomeScrollOffsetReader { offsetY in
                            updateFilterToolbarVisibility(offsetY > inlineFilterHideOffset)
                        }
                    }
            }
        }
        .scrollDisabled(expand)
        .modifier(HomeScrollOffsetModifier { offsetY in
            updateFilterToolbarVisibility(offsetY > inlineFilterHideOffset)
        })
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 44)
        }
        .overlay(alignment: .top) {
            customToolbar
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: expand) { isExpanded in
            if isExpanded {
                updateFilterToolbarVisibility(false)
                searchViewModel.isSearching = true
                // Focus after the panel paints — keyboard + first glass/material
                // creation in the same frame is what felt like a cold-start hang.
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
                    .font(.custom("Rubik-Medium", size: 22))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 24)

                Button(action: { presentPopup = true }) {
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

    private func updateFilterToolbarVisibility(_ shouldShow: Bool) {
        guard shouldShow != showFilterInToolbar else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            showFilterInToolbar = shouldShow
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

    private var customToolbar: some View {
        Group {
            if expand {
                VStack(spacing: 0) {
                    // Search field row
                    HStack(spacing: 12) {
                        TextField(
                            "",
                            text: $searchText,
                            prompt: Text("What are you looking for?")
                                .foregroundColor(Constants.Colors.secondaryGray)
                        )
                        .font(Constants.Fonts.body2)
                        .foregroundStyle(Constants.Colors.black)
                        .submitLabel(.search)
                        .focused($searchFocused)
                        .onSubmit { runSearch(searchText) }

                        Button {
                            withAnimation(.snappy(duration: 0.2)) { expand = false }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Constants.Colors.black)
                                .frame(width: 32, height: 32)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                    // Recent searches — same card, below the field
                    if searchViewModel.isSearching && !mainViewModel.searchHistory.isEmpty {
                        Divider().padding(.horizontal, 4)

                        let history = Array(mainViewModel.searchHistory.prefix(5))
                        ForEach(history, id: \.self) { query in
                            Button {
                                searchText = query
                                runSearch(query)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Constants.Colors.secondaryGray)
                                    Text(query)
                                        .font(Constants.Fonts.body1)
                                        .foregroundStyle(Constants.Colors.black)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            if query != history.last {
                                Divider().padding(.horizontal, 4)
                            }
                        }
                        .padding(.bottom, 4)
                    }
                }
                // Opaque panel — avoid glassEffect here; first materialization of a
                // large glass surface was the cold-start hang when opening search.
                .background {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Constants.Colors.white)
                        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 6)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                }
                .padding(.horizontal, Constants.Spacing.horizontalPadding)
                .frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 10) {
                    if showFilterInToolbar {
                        floatingFilterButton
                            .transition(.opacity.combined(with: .scale(scale: 0.85)))
                    }

                    // Principal search pill — tap expands into the full search panel.
                    Button {
                        expand = true
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

                    Button {
                        router.push(.notifications)
                    } label: {
                        Image(systemName: "bell")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.black)
                            .frame(width: 18, height: 18)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(.plain)
                    .frame(width: toolbarControlHeight, height: toolbarControlHeight)
                    .modifier(GlassToolbarModifier())
                }
                .padding(.horizontal, Constants.Spacing.horizontalPadding)
                .frame(height: toolbarControlHeight)
                .animation(.easeInOut(duration: 0.2), value: showFilterInToolbar)
            }
        }
    }

    private var toolbarControlHeight: CGFloat { 40 }

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
    }

    // MARK: - Helpers

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

    private var headerView: some View {
        HStack {
            Text("resell")
                .font(Constants.Fonts.resellHeader)
                .foregroundStyle(Constants.Colors.resellGradient)

            Spacer()
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
    }
    

}

struct GlassToolbarModifier: ViewModifier {
    var cornerRadius: CGFloat = 999
    var isOpaque: Bool = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        // Material / glassEffect alone don't always claim the full pill for hits —
        // match the tab bar: near-clear fill + contentShape over the laid-out frame.
        if #available(iOS 26, *) {
            content
                .background {
                    shape.fill(Color.white.opacity(isOpaque ? 0.55 : 0.001))
                }
                .contentShape(shape)
                .glassEffect(.regular, in: shape)
        } else {
            content
                .background {
                    shape.fill(Color.white.opacity(0.001))
                }
                .contentShape(shape)
                .background(isOpaque ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.ultraThinMaterial), in: shape)
        }
    }
}

/// iOS 18+: native scroll geometry. Earlier: UIKit contentOffset KVO.
private struct HomeScrollOffsetModifier: ViewModifier {
    let onOffsetChange: (CGFloat) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y
            } action: { _, newOffset in
                onOffsetChange(newOffset)
            }
        } else {
            content
        }
    }
}

/// Observes the enclosing UIScrollView's contentOffset — more reliable than
/// SwiftUI PreferenceKeys for driving toolbar chrome while scrolling.
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
            if scrollView != nil { return }
            // Walk up after layout so the SwiftUI ScrollView host exists.
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
