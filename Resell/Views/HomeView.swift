//
//  HomeView.swift
//  Resell
//
//  Created by Richie Sun on 9/11/24.
//

import SwiftUI

struct HomeView: View {

    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                headerView
                filtersView
                ProductsGalleryView(items: [
                    Item(id: UUID(), title: "Justin", image: "justin", price: "$100", category: "School"),
                    Item(id: UUID(), title: "Justin", image: "justin_long", price: "$100", category: "School"),
                    Item(id: UUID(), title: "Justin", image: "justin_long", price: "$100", category: "School"),
                    Item(id: UUID(), title: "Justin", image: "justin", price: "$100", category: "School"),
                    Item(id: UUID(), title: "Justin", image: "justin_long", price: "$100", category: "School"),
                    Item(id: UUID(), title: "Justin", image: "justin", price: "$100", category: "School"),
                ])
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
                // Search Endpoint
            }, label: {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Constants.Colors.black)
            })
        }
        .padding(.horizontal, 25)
        .padding(.top, 64)
    }

    private var filtersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Constants.filters, id: \.id) { filter in
                    ResellFilterButton(filter: filter, isSelected: viewModel.selectedFilters.contains(filter)) {
                        viewModel.toggleFilter(filter)
                    }
                }
            }
            .padding(.leading, 25)
            .padding(.vertical, 1)
        }
    }
}

#Preview {
    HomeView()
}