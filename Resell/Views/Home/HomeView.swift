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
        NavigationStack(path: $router.path) {
            VStack(spacing: 0) {
                headerView

                filtersView
                    .padding(.bottom, 12)

                ProductsGalleryView(items: viewModel.filteredItems)
            }
            .background(Constants.Colors.white)
            .overlay(alignment: .bottomTrailing) {
                ExpandableAddButton()
                    .padding(.bottom, 40)
            }
            .onAppear {
                viewModel.getAllPosts()
                viewModel.getBlockedUsers()

                withAnimation {
                    mainViewModel.hidesTabBar = false
                }
            }
            .refreshable {
                viewModel.getAllPosts()
            }
            .loadingView(isLoading: viewModel.isLoading)
            .navigationBarBackButtonHidden()
        }
        .sheet(isPresented: $presentPopup) {
            FilterView()
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
            HStack{
                Button(action: {
                    router.push(.search(nil))
                }, label: {
                    RoundedRectangle(cornerRadius: 40)
                        .frame(width: 309, height: 43)
                        .overlay {
                            HStack {
                                Spacer()
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.black)
                                Text("Search")
                                    .font(Constants.Fonts.body1)
                                    .foregroundColor(Constants.Colors.black)
                                Spacer()
                            }
                        }
                        .foregroundColor(Constants.Colors.wash)
                        .padding(.horizontal, Constants.Spacing.horizontalPadding)
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Constants.filters, id: \.id) { filter in
                    FilterButton(filter: filter, isSelected: viewModel.selectedFilter == filter.title) {
                        viewModel.selectedFilter = filter.title
                    }
                }
            }
            .padding(.leading, Constants.Spacing.horizontalPadding)
            .padding(.vertical, 1)
        }
    }
}



