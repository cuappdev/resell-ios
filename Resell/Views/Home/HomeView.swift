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
    @EnvironmentObject var router: Router
    @StateObject private var viewModel = HomeViewModel.shared
    @State var presentPopup = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack {
                    savedByYou
                    filtersView
                        .padding(.top, 12)
                    ProductsGalleryView(items: viewModel.filteredItems)
                }
            }
            
            
                .padding(.top, 12)
        }
        .onAppear {
            viewModel.getAllPosts()
            viewModel.getBlockedUsers()
            withAnimation { mainViewModel.hidesTabBar = false }
        }
        .background(Constants.Colors.white)
        .overlay(alignment: .bottomTrailing) {
            ExpandableAddButton().padding(.bottom, 40)
        }
        .refreshable { viewModel.getAllPosts() }
        .loadingView(isLoading: viewModel.isLoading)
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $presentPopup) {
            FilterView(home: true)
        }
    }
    
    
    private var savedByYou: some View {
            VStack{
                HStack(spacing: 156) {
                    Text("Saved By You")
                        .font(.custom("Rubik-Medium", size: 22))
                        .foregroundStyle(.black)
                    
                    
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
                // if there are no saved posts
                if viewModel.savedItems.isEmpty {
                    ZStack{
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .frame(width: 366, height: 110)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray, lineWidth: 4)
                            )
                        VStack{
                            Text("No Listings are Saved.")
                            Text("Browse below to get started.")
                        }
                    }
                    // if there are saved posts
                    // load the first X posts, then have a view more button that navigates to the saved view
                    
                } else {
                    SavedRow(row: viewModel.savedItems)
                }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("resell")
                    .font(Constants.Fonts.resellHeader)
                    .foregroundStyle(Constants.Colors.resellGradient)
                
                Spacer()
                
                Button(action: {
                    router.push(.notifications)
                }, label: {
                    Icon(image: "bell")
                })
                
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
            .padding(.vertical, -4)
            HStack{
                Button(action: {
                    router.push(.search(nil))
                }, label: {
                    SearchBar()
                })
                
                Button(action: {
                    presentPopup = true
                }, label: {
                    Image("filters")
                        .resizable()
                        .frame(width: 40, height: 40)
                })
            }
            .padding(.bottom,12)
            .padding(.horizontal, Constants.Spacing.horizontalPadding)

            
            Button(action: {
                router.push(.search(nil))
            }, label: {
                Icon(image: "bell")
            })
//            Button(action: {
//                router.push(.search(nil))
//            }, label: {
//                Icon(image: "search")
//            })
        }
    }

    private var filtersView: some View {
            VStack(alignment: .leading) {
                Text("Shop By Category")
                    .font(.custom("Rubik-Medium", size: 22))
                    .foregroundStyle(.black)
                    .padding(.leading, Constants.Spacing.horizontalPadding)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Constants.filters.filter { $0.color != nil }, id: \.id) { filter in
                            VStack{
                                 
                                    CircularFilterButton(filter: filter, isSelected: viewModel.selectedFilter == filter.title) {
                                        router.push(.detailedFilter(filter))
                                        viewModel.selectedFilter = filter.title
                                    }
                                
                                Text(filter.title)
                                    .font(Constants.Fonts.title4)
                                
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(Constants.Colors.black)
                            }
                        }.padding(.trailing, 30)
                    }
                    .padding(.leading, Constants.Spacing.horizontalPadding)
                    .padding(.vertical, 1)
                }
            }
        }
    }
    



