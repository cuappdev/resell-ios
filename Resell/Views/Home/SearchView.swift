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
    @EnvironmentObject var router: Router
    @FocusState private var isFocused: Bool

    @State private var isLoading: Bool = false
    @State private var isSearching: Bool = true

    @State private var searchedItems: [Post] = []
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
                        searchItems()
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

            if isSearching {
                searchHistoryView

                Spacer()
            } else if isLoading {
                Spacer()

                ProgressView()

                Spacer()
            } else {
                if searchedItems.isEmpty {
                    Spacer()

                    emptyState

                    Spacer()
                } else {
                    ProductsGalleryView(items: searchedItems)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .background(Constants.Colors.white)
        .loadingView(isLoading: isLoading)
        .onChange(of: isFocused) { newValue in
            isSearching = newValue
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
                        searchItems()
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

    // MARK: - Functions

    private func searchItems() {
        isSearching = false
        isLoading = true

        Task {
            defer { Task { @MainActor in withAnimation { isLoading = false } } }
            
            do {
                let postsResponse = try await NetworkManager.shared.getSearchedPosts(with: searchText)

                if let userID {
                    searchedItems = postsResponse.posts.filter { $0.user?.firebaseUid == userID }
                } else {
                    searchedItems = postsResponse.posts
                }
                
                mainViewModel.saveSearchQuery(searchText)
            } catch {
                NetworkManager.shared.logger.error("Error in SearchView.searchItems: \(error)")
            }
        }
    }
}
