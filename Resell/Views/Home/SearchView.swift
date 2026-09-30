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
        contentView
            .safeAreaInset(edge: .top, spacing: 0) {
                searchHeader
            }
        .navigationBarBackButtonHidden()
        .background(Constants.Colors.white)
        .loadingView(isLoading: searchViewModel.isLoading)
        .onChange(of: isFocused) { newValue in
            searchViewModel.isSearching = newValue
        }
    }

    private var searchHeader: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                TextField("", text: $searchText, prompt: Text("What are you looking for?").foregroundColor(Constants.Colors.secondaryGray))
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.black)
                    .submitLabel(.search)
                    .padding(12)
                    .glassEffect(.regular, in: .capsule)
                    .focused($isFocused)
                    .onSubmit {
                        searchViewModel.searchItems(with: searchText, userID: userID, saveQuery: false, mainViewModel: mainViewModel) {}
                    }

                Button {
                    router.pop()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(Constants.Colors.black)
                        .padding(14)
                }
                .glassEffect(.regular.interactive(), in: .circle)
            }
            .padding(Constants.Spacing.horizontalPadding)
        }
    }

    private var contentView: some View {
        Group {
            if searchViewModel.isSearching {
                searchHistoryView
            } else if searchViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchViewModel.searchedItems.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical) {
                    ProductsGalleryView(items: searchViewModel.searchedItems)
                }
            }
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
