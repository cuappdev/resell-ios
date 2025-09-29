//
//  ForYouView.swift
//  Resell
//
//  Created by Charles Liggins on 9/12/25.
//

import SwiftUI
import Kingfisher

struct ForYouView: View {
    @StateObject private var viewModel = HomeViewModel.shared
    @StateObject private var searchViewModel = SearchViewModel.shared

    @State private var imageLoadedStates: [Bool]
    @State private var dataLoaded: Bool = false
    
    @State private var data: [[Post]] = []
    private var titles: [String] = ["Saved By You", "Recently Searched"]
    
    init() {
        _imageLoadedStates = State(initialValue: Array(repeating: false, count: 2))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("For You")
                .font(.custom("Rubik-Medium", size: 22))
                .foregroundStyle(.black)
                .padding(.leading, 24)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 20) {
                    if dataLoaded {
                        // TODO: Refactor if we have a large amount of cards
                        forYouCard(title: titles[0], posts: viewModel.savedItems, loaded: $imageLoadedStates[0])
                        forYouCard(title: titles[1], posts: searchViewModel.recentlySearched, loaded: $imageLoadedStates[1])
                        }
                    }
                .padding(.leading, 24)

                }
            }
            .onAppear() {
                viewModel.getSavedPosts() {
                    viewModel.getRecentlySearched() {
                        // Now on main thread, update your state
                        DispatchQueue.main.async {
                            dataLoaded = true
                        }
                    }
                }
            }
         }
    }

    func forYouCard(title: String, posts: [Post], loaded: Binding<Bool>) -> some View {
        ZStack {
            LazyVGrid(columns: [GridItem(.fixed(120), spacing: 0), GridItem(.fixed(120), spacing: 0)], spacing: 0) {
                ForEach(Array(posts.enumerated()).prefix(4), id: \.element) { index, item in
                    CachedImageView(isImageLoaded: loaded, isForYou: true, imageURL: URL(string: item.images.first ?? ""))
                        .frame(width: 120, height: 120)
                        .overlay(
                                index >= 2 ?
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.black.opacity(0.8), // very dark at bottom
                                            Color.black.opacity(0.5), // fading upward
                                            Color.clear // fully transparent by middle
                                        ]),
                                        startPoint: .bottom, endPoint: .top
                                    )
                                    .frame(height: 60) // covers the bottom half
                                    .frame(maxHeight: .infinity, alignment: .bottom)
                                : nil
                            )
                        }
                    }
                Text(title)
                    .foregroundStyle(Color.white)
                    .font(Constants.Fonts.title1)
                    .offset(x: -24, y: 94)
            }
            .frame(width: 240, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
