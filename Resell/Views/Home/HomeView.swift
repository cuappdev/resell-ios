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

    var body: some View {
            ScrollView(.vertical, showsIndicators: true) {
                VStack {
                    headerView
                    
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
            if !viewModel.hasActiveFilters {
                viewModel.getAllPosts() //only get all posts if no filters are applied
            } else {
            }
            viewModel.getBlockedUsers()
            withAnimation { mainViewModel.hidesTabBar = false }
        }
        .onDisappear {
            // Clean up image cache when leaving home view
            viewModel.cleanupMemory()
        }
        .background(Constants.Colors.white)
        .overlay(alignment: .bottomTrailing) {
            ExpandableAddButton().padding(.bottom, 40)
        }
        .refreshable {
            // Force refresh when user pulls to refresh
            viewModel.getAllPosts(forceRefresh: true)
        }
        .loadingView(isLoading: viewModel.isLoading)
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $presentPopup) {
            FilterView(home: true, isPresented: $presentPopup)
                .environmentObject(filtersViewModel)
        }
    }

    private var headerView: some View {
            HStack {
                    Text("resell")
                        .font(Constants.Fonts.resellHeader)
                        .foregroundStyle(Constants.Colors.resellGradient)

                    Spacer()

                    Button(action: {
                        router.push(.search(nil))
                    }, label: {
                        Icon(image: "search")
                    })
            
                    Button(action: {
                        router.push(.notifications)
                    }, label: {
                        Image(systemName: "bell") // using the native sfsymbols bell is faster + prettier
                            .font(.system(size: 20, weight: .medium)) // Increases thickness to bold
                            .foregroundStyle(.black)
                    })
                    .padding(.leading, 12)
                }
                .padding(.horizontal, Constants.Spacing.horizontalPadding)

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
