//
//  SuggestionsView.swift
//  Resell
//
//  Created by Charles Liggins on 10/10/25.
//

// MARK: This is also not used anywhere currently....

// MARK: This will likely be refactored I'm just going based off of not too many designs...
// This is essentially a recently searched view as of now, as I'm unsure how else we can use it...

import SwiftUI

struct SuggestionsView: View {
    // Take a few (<= 5) recent searches, then show the posts here...
    @StateObject private var searchViewModel = SearchViewModel.shared
    @EnvironmentObject var router: Router

    @State private var suggestedPosts: [Post] = []
    @State private var isLoading = false
    
    var body: some View {
        ScrollView{
            VStack {
                Text("Suggested For You")
                    .font(.custom("Rubik-Medium", size: 22))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                } else if suggestedPosts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(.gray)
                        
                        Text("No suggestions yet")
                            .font(Constants.Fonts.title2)
                        
                        Text("Search for items to get personalized suggestions")
                            .font(Constants.Fonts.body1)
                            .foregroundStyle(Constants.Colors.secondaryGray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ProductsGalleryView(
                        items: suggestedPosts,
                        onScrollToBottom: {}
                    )
                }
            }
            .navigationTitle("Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadSuggestions()
            }
        }
        .background(Constants.Colors.white)
    }
      
    private func loadSuggestions() {
           guard suggestedPosts.isEmpty else { return }
           
           isLoading = true
           Task {
               defer { isLoading = false }
               suggestedPosts = await searchViewModel.loadAllSuggestions()
           }
       }
}
