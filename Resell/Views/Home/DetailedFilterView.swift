//
//  DetailedFilterView.swift
//  Resell
//
//  Created by Charles Liggins on 4/27/25.
//

import SwiftUI

// TODO: Consolidate SavedView and DetailedFilterView into one view...
struct DetailedFilterView: View {

    // pass through the filtersVM
    @State var presentPopup = false
    @EnvironmentObject var router: Router
    let filter : FilterCategory
    
    @StateObject private var filtersViewModel = FiltersViewModel(isHome: false)
    @StateObject private var viewModel = HomeViewModel.shared

    var body: some View {
    
        ZStack {
            VStack(spacing: 0) {
                headerView
                ScrollView(.vertical) {
                    ProductsGalleryView(items: filtersViewModel.detailedFilterItems)
                }
            }
        }
        .background(Constants.Colors.white)
        .loadingView(isLoading: viewModel.isLoading)
        .emptyState(isEmpty: $viewModel.filteredItems.isEmpty, title: "No \(filter.title) posts", text: "Posts in the \(filter.title) category will be displayed here.")
        .onAppear {
            viewModel.getBlockedUsers()
            Task {
                try await filtersViewModel.initializeDetailedFilter(category: filter.title)
            }
        }
        .sheet(isPresented: $presentPopup) {
            FilterView(home: false, isPresented: $presentPopup)
                .environmentObject(filtersViewModel)
        }
    }

    private var headerView: some View {
        VStack{
            HStack (spacing: 64){
                Button {
                    router.pop()
                } label: {
                    Image("chevron.left.white")
                        .resizable()
                        .frame(width: 36, height: 24)
                }
                
                Text(filter.title)
                    .font(Constants.Fonts.h1)
                    .foregroundStyle(Constants.Colors.black)
                
                Spacer()
            }
            .padding(.horizontal, 25)
            
            HStack{
                Button(action: {
                    // TODO: refactor search for detailed filter
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
        }
        
    }
}
