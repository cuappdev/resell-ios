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
    
    @StateObject private var viewModel = HomeViewModel.shared
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
                                .frame(width: 40, height: 40)
                        })
                        .padding(.trailing, 24)
                    }
                    
                    ProductsGalleryView(items: viewModel.filteredItems, onScrollToBottom: viewModel.fetchMoreItems)
            }
                .padding(.top, 12)
        }
        .onAppear {
            // Only fetch if we don't have cached data
            viewModel.getAllPosts()
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
    
    private var savedByYou: some View {
            VStack{
                HStack(spacing: 220) {
                    Text("For You")
                        .font(.custom("Rubik-Medium", size: 22))
                        .foregroundStyle(.black)
                    
                    // TODO: Add new for you ...
                    Button {
                        router.push(.saved)
                    } label: {
                        Text("See all")
                            .font(Constants.Fonts.body1)
                            .underline()
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Constants.Colors.secondaryGray)
                    }
                }
                if viewModel.savedItems.isEmpty {
                    ZStack{
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .frame(width: 366, height: 110)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Constants.Colors.stroke, lineWidth: 2)
                            )
                        
                        VStack{
                            Text("You haven't saved any listings yet.")
                                .foregroundStyle(Constants.Colors.secondaryGray)
                            HStack{
                                Text("Tap")
                                    .foregroundStyle(Constants.Colors.secondaryGray)
                                
                                Image("saved")
                                
                                Text("on a listing to save.")
                                    .foregroundStyle(Constants.Colors.secondaryGray)
                            }
                        }
                    }
                } else {
                    SavedRow(row: viewModel.savedItems)
                }
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
