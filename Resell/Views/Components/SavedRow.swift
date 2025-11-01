//
//  SavedRow.swift
//  Resell
//
//  Created by Charles Liggins on 4/26/25.
//

import SwiftUI

struct SavedRow: View {
    
    @State private var selectedItem: Post? = nil
    @EnvironmentObject var router: Router
    
    let row : [Post]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(row) { post in
                    Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
                }
            }
        }
    }
}
