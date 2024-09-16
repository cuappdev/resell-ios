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
            VStack(spacing: 0) {
                headerView

                filtersView

                ProductsGalleryView(items: [
                    Item(id: UUID(), title: "Justin", image: "justin", price: "$100", category: "School"),
                    Item(id: UUID(), title: "Justin", image: "justin_long", price: "$100", category: "School"),
                    Item(id: UUID(), title: "Justin", image: "justin_long", price: "$100", category: "School"),
                    Item(id: UUID(), title: "Justin", image: "justin", price: "$100", category: "School"),
                    Item(id: UUID(), title: "Justin", image: "justin_long", price: "$100", category: "School"),
                    Item(id: UUID(), title: "Justin", image: "justin", price: "$100", category: "School"),
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
            .padding(.leading, 25)
            .padding(.vertical, 1)
            .padding(.bottom, 12)
        }
    }
}

#Preview {
    HomeView()
}
