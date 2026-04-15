//
//  ForYouView.swift
//  Resell
//
//  Created by Charles Liggins on 9/12/25.
//

import SwiftUI
import Kingfisher

struct ForYouView: View {
    @ObservedObject private var viewModel = HomeViewModel.shared
    @ObservedObject private var searchViewModel = SearchViewModel.shared
    @EnvironmentObject var router: Router

    @State private var recentPosts: [Post] = [] // Fetched on demand
    
    private var titles: [String] = ["Saved By You", "Recently Searched"]
    
    @State private var savedLoadedStates: [Bool] = Array(repeating: false, count: 4)
    @State private var recentLoadedStates: [Bool] = Array(repeating: false, count: 4)
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("For You")
                .font(.custom("Rubik-Medium", size: 22))
                .foregroundStyle(.black)
                .padding(.leading, 24)
            
            if !viewModel.savedItems.isEmpty || !recentPosts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 20) {
                        if !viewModel.savedItems.isEmpty {
                            forYouCard(title: titles[0], posts: viewModel.savedItems, loaded: $savedLoadedStates)
                        }
                        if !recentPosts.isEmpty {
                            forYouCard(title: titles[1], posts: recentPosts, loaded: $recentLoadedStates)
                        }
                    }
                    .padding(.leading, 24)
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                        .foregroundStyle(.white)

                    VStack {
                        Text("You haven't saved any listings yet.")
                            .foregroundStyle(Constants.Colors.black)
                        
                        Text("Tap \(Image(systemName: "bookmark")) on a listing to save.")
                            .foregroundStyle(Constants.Colors.black)
                    }
                }
                .frame(height: 110)
                .padding(.horizontal, 24)
            }
        }
        .onAppear() {
            Task {
                async let saved: () = viewModel.getSavedPosts()
                
                print("trying to load recently searched")
                let recent = await searchViewModel.loadRecentlySearchedPosts()
                recentPosts = recent
                
                await saved
            }
        }
    }
    
    func forYouCard(title: String, posts: [Post], loaded: Binding<[Bool]>) -> some View {
        Button {
            if title == "Saved By You" {
                router.push(.saved)
            } else if title == "Recently Searched" {
                router.push(.discover)
            }
        } label: {
            ZStack {
                if posts.count >= 4 {
                    LazyVGrid(columns: [GridItem(.fixed(120), spacing: 0), GridItem(.fixed(120), spacing: 0)], spacing: 0) {
                        ForEach(Array(posts.enumerated().prefix(4)), id: \.element.id) { index, item in
                            CachedImageView(
                                isImageLoaded: loaded[index],
                                imageURL: URL(string: item.images.first ?? "")
                            )
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipped()
                            .overlay(
                                index >= 2 ?
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.black.opacity(0.8),
                                        Color.black.opacity(0.5),
                                        Color.clear
                                    ]),
                                    startPoint: .bottom, endPoint: .top
                                )
                                .frame(height: 60)
                                .frame(maxHeight: .infinity, alignment: .bottom)
                                : nil
                            )
                        }
                    }
                } else if posts.count > 0 {
                    CachedImageView(
                        isImageLoaded: loaded[0],
                        imageURL: URL(string: posts[0].images.first ?? "")
                    )
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 240, height: 240)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.8),
                                Color.black.opacity(0.5),
                                Color.clear
                            ]),
                            startPoint: .bottom, endPoint: .top
                        )
                        .frame(height: 120)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                    )
                }
                
                Text(title)
                    .foregroundStyle(Color.white)
                    .font(Constants.Fonts.title1)
                    .offset(x: -24, y: 94)
            }
            .frame(width: 240, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}
