//
//  HomeView.swift
//  Resell
//
//  Created by Richie Sun on 9/11/24.
//

import Kingfisher
import OAuth2
import SwiftUI

private struct FilterRowMinYKey: PreferenceKey {
    static var defaultValue: CGFloat = .greatestFiniteMagnitude
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

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

    var body: some View {
        ScrollView(.vertical, showsIndicators: !expand) {
            if expand && !searchViewModel.isSearching {
                searchResultsContent
                    .padding(.top, 12)
            } else {
                homeFeedContent
                    .padding(.top, 12)
            }
        }
        .onPreferenceChange(FilterRowMinYKey.self) { minY in
            withAnimation(.easeInOut(duration: 0.2)) {
                showFilterInToolbar = minY < 130
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 44)
        }
        
        .overlay(alignment: .top) {
            customToolbar
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: expand) { isExpanded in
            if isExpanded {
                searchViewModel.isSearching = true
                searchFocused = true
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
            CategoriesView()

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
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: FilterRowMinYKey.self,
                        value: geo.frame(in: .global).minY
                    )
                }
            )

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
                .modifier(GlassToolbarModifier(cornerRadius: 22, isOpaque: true))
                .padding(.horizontal, Constants.Spacing.horizontalPadding)
                .frame(maxWidth: .infinity)
                .transition(.opacity)
            } else {
                ZStack(alignment: .top) {
                    if showFilterInToolbar {
                        HStack {
                            floatingFilterButton
                            Spacer()
                        }
                        .padding(.leading, Constants.Spacing.horizontalPadding)
                        .frame(height: 44)
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                    }

                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.snappy(duration: 0.2)) { expand = true }
                        } label: {
                            Icon(image: "search")
                        }

                        Button {
                            router.push(.notifications)
                        } label: {
                            Image(systemName: "bell")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.black)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .modifier(GlassToolbarModifier())
                    .padding(.trailing, Constants.Spacing.horizontalPadding)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .frame(height: 44)
                }
                .transition(.opacity)
            }
        }
    }

    private var floatingFilterButton: some View {
        Button {
            presentPopup = true
        } label: {
            Image("filters")
                .resizable()
                .frame(width: 22, height: 19)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
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

private struct GlassToolbarModifier: ViewModifier {
    var cornerRadius: CGFloat = 999
    var isOpaque: Bool = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26, *) {
            content
                .background(shape.fill(Color.white.opacity(isOpaque ? 0.55 : 0)))
                .glassEffect(.regular, in: shape)
        } else {
            content.background(isOpaque ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.ultraThinMaterial), in: shape)
        }
    }
}
