//
//  SearchView.swift
//  Resell
//
//  Created by Richie Sun on 11/4/24.
//

import SwiftUI

struct SearchView: View {

    // MARK: - Properties

    @EnvironmentObject private var mainViewModel: MainViewModel
    @EnvironmentObject private var searchViewModel: SearchViewModel
    @EnvironmentObject var router: Router
    @FocusState private var isFocused: Bool

    @State private var searchText: String = ""

    var userID: String? = nil

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                TextField("", text: $searchText, prompt: Text("What are you looking for?").foregroundColor(Constants.Colors.secondaryGray))
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.black)
                    .submitLabel(.search)
                    .padding(12)
                    .background(Constants.Colors.wash)
                    .clipShape(.capsule)
                    .focused($isFocused)
                    .onSubmit {
                        searchViewModel.searchItems(with: searchText, userID: userID, saveQuery: true, mainViewModel: mainViewModel) {}
                    }

                Button {
                    router.pop()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(Constants.Colors.black)
                }
            }
            .padding(Constants.Spacing.horizontalPadding)

            if searchViewModel.isSearching {
                searchHistoryView

                Spacer()
            } else if searchViewModel.isLoading {
                Spacer()

                ProgressView()

                Spacer()
            } else {
                if searchViewModel.searchedItems.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    ScrollView(.vertical) {
                        ProductsGalleryView(items: searchViewModel.searchedItems)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .background(Constants.Colors.white)
        .loadingView(isLoading: searchViewModel.isLoading)
        .onChange(of: isFocused) { newValue in
            searchViewModel.isSearching = newValue
        }
    }

    private var emptyState: some View {
        VStack {
            Text("No results")
                .font(Constants.Fonts.h2)
                .foregroundStyle(Constants.Colors.black)
                .padding(.bottom, 12)

            Text("Try another search or")
                .font(Constants.Fonts.body1)
                .multilineTextAlignment(.center)
                .foregroundStyle(Constants.Colors.secondaryGray)

            Button {
                router.push(.newRequest)
            } label: {
                Text("submit a request")
                    .font(Constants.Fonts.body1)
                    .underline()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Constants.Colors.secondaryGray)
            }
        }
        .frame(width: 300)
    }

    private var searchHistoryView: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(mainViewModel.searchHistory, id: \.self) { query in
                    Button {
                        searchText = query
                        searchViewModel.searchItems(with: searchText, userID: userID, saveQuery: true, mainViewModel: mainViewModel) {}
                    } label: {
                        Text(query)
                            .font(Constants.Fonts.body1)
                            .foregroundStyle(Constants.Colors.secondaryGray)

                        Spacer()
                    }
                }
            }
            .padding(.horizontal, Constants.Spacing.horizontalPadding)
        }
    }    
}
