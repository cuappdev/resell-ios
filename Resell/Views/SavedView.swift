//
//  SavedView.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import SwiftUI

struct SavedView: View {

    @StateObject private var viewModel = HomeViewModel.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerView
                ProductsGalleryView(items: viewModel.savedItems)
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text("Saved")
                .font(Constants.Fonts.h1)
                .foregroundStyle(Constants.Colors.black)
            Spacer()
            Button(action: {
                // Search Endpoint
            }, label: {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Constants.Colors.black)
            })
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 24)
    }
}
