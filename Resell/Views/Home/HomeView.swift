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

            filtersView
                .padding(.bottom, 12)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack{
                        savedByYou
                        ProductsGalleryView(items: viewModel.filteredItems)
                    }
                }
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
    
    private var savedByYou: some View {
            VStack{
                HStack(spacing: 96){
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
                    RoundedRectangle(cornerRadius: 40)
                        .frame(width: 309, height: 43)
                        .overlay {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.black)
                                    .padding(.leading, 16)
                                Text("Search")
                                    .font(Constants.Fonts.body1)
                                    .foregroundColor(Constants.Colors.black)
                                Spacer()
                            }
                        }
                        .foregroundColor(Constants.Colors.wash)
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



