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

    var body: some View {
        VStack {
            ForEach(searchViewModel.recentlySearched, id: \.self) { search in
                Text(search.title)
            }
        }
    }
    
    func suggestions_section(search: Post) -> some View {
        VStack {
            Text(search.title)
            
        }
    }
}

