//
//  HomeView.swift
//  Resell
//
//  Created by Richie Sun on 9/11/24.
//

import Kingfisher
import OAuth2
import SwiftUI

struct HomeView: View {

    @EnvironmentObject private var mainViewModel: MainViewModel
    @EnvironmentObject private var searchViewModel: SearchViewModel
    @EnvironmentObject var router: Router
    
    @ObservedObject private var viewModel = HomeViewModel.shared
    @StateObject private var filtersViewModel = FiltersViewModel(isHome: true)
    
    @State var forYouPosts: [[Post]] = []
    @State private var presentPopup = false
    /// Bottom safe-area inset (tab bar + home indicator), captured so the
    /// dropped button can align its center with the minimized tab bar pill.
    @State private var bottomSafeAreaInset: CGFloat = 0

    var body: some View {
            ScrollView(.vertical, showsIndicators: true) {
                VStack {
                    filtersView
                        .padding(.top, 12)
                        .padding(.bottom, 32)
                    
                    ForYouView()
                        .padding(.bottom, 32)
                    
                    HStack {
                        Text("Recent Listings")
                            .font(.custom("Rubik-Medium", size: 22))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, alignment: .leading) // <-- Align text left
                            .padding(.leading, 24)
                        
                        Button(action: {
                            presentPopup = true
                        }, label: {
                            Image("filters")
                                .resizable()
                                .frame(width: 24, height: 21)
                                .padding(12)
                                .contentShape(Rectangle())
                        })
                        .padding(.trailing, 12)
                    }
                    .padding(.bottom, 4)
                    
                    ProductsGalleryView(items: viewModel.filteredItems, onScrollToBottom: viewModel.fetchMoreItems)
            }
                .padding(.top, 12)
        }
        .onAppear {
            // Only fetch if we don't have cached data
            if !viewModel.isFilteredFeed {
                viewModel.getAllPosts() //only get all posts if no filters are applied
            }
            viewModel.getBlockedUsers()
        }
        .onDisappear {
            // Clean up image cache when leaving home view
            viewModel.cleanupMemory()
        }
        .background(Constants.Colors.white)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { oldValue, newValue in
            mainViewModel.updateTabBarForScroll(offset: newValue, previousOffset: oldValue)
        }
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { bottomSafeAreaInset = proxy.safeAreaInsets.bottom }
            }
        )
        .overlay(alignment: .bottomTrailing) {
            // Dropped position: button bottom edge 16pt above the screen edge,
            // which centers the 64pt button on the minimized tab bar pill.
            ExpandableAddButton()
                .padding(.bottom, 8)
                .offset(y: mainViewModel.isTabBarMinimized ? max(bottomSafeAreaInset - 4, 56) : 0)
                .animation(.spring(duration: 0.35), value: mainViewModel.isTabBarMinimized)
        }
        .refreshable {
            // Force refresh when user pulls to refresh
            if viewModel.isFilteredFeed {
                Task {
                    try? await filtersViewModel.applyFilters(homeViewModel: viewModel)
                }
            } else {
                viewModel.getAllPosts(forceRefresh: true)
            }
        }
        .loadingView(isLoading: viewModel.isLoading)
        .sheet(isPresented: $presentPopup) {
            FilterView(home: true, isPresented: $presentPopup)
                .environmentObject(filtersViewModel)
                .presentationDragIndicator(.visible)
        }
    }


    private var filtersView: some View {
            VStack(alignment: .leading) {
                Text("Shop By Category")
                    .font(.custom("Rubik-Medium", size: 22))
                    .foregroundStyle(.black)
                    .padding(.leading, Constants.Spacing.horizontalPadding)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top) {
                        ForEach(Constants.filters.filter { $0.color != nil }, id: \.id) { filter in
                            VStack {
                                CircularFilterButton(filter: filter) { router.push(.detailedFilter(filter)) }
                                
                                Text(filter.title)
                                    .font(Constants.Fonts.title4)
                                    .frame(width: 80)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(Constants.Colors.black)
                            }
                        }
                        .padding(.trailing, 30)
                    }
                    .padding(.leading, Constants.Spacing.horizontalPadding)
                    .padding(.vertical, 1)
                }
            }
        }
    }
