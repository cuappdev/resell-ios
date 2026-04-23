//
//  SavedView.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import SwiftUI

struct SavedView: View {
    // TODO: This should be the same as the detailed filter view imo...
    @EnvironmentObject var router: Router
//    @EnvironmentObject private var viewModel: HomeViewModel
    @ObservedObject private var viewModel = HomeViewModel.shared
    
    var body: some View {
        ScrollView(.vertical){
            ProductsGalleryView(items: viewModel.savedItems)
        }
        .background(Constants.Colors.white)
        .loadingView(isLoading: viewModel.isLoading)
        .emptyState(isEmpty: $viewModel.savedItems.isEmpty, title: "No saved posts", text: "Posts you have bookmarked will be displayed here.")
        .refreshable {
            Task {
                await viewModel.getSavedPosts()
            }
        }
        .onAppear {
            Task {
                await viewModel.getSavedPosts()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    router.pop()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Constants.Colors.black)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("Saved By You")
                    .font(Constants.Fonts.h1)
                    .foregroundStyle(Constants.Colors.black)
            }
        }
    }
    
    private var headerView: some View {
        VStack {
            Text("Saved By You")
                .font(Constants.Fonts.h1)
                .foregroundStyle(Constants.Colors.black)
        }
        .padding(.horizontal, 25)
    }
}
