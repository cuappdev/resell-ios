//
//  SearchBar.swift
//  Resell
//
//  Created by Charles Liggins on 4/27/25.
//

import SwiftUI

struct SearchBar: View {

    var body: some View {
        RoundedRectangle(cornerRadius: 40)
            .frame(width: 309, height: 43)
            .overlay {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.black)
                        .padding(.leading, 16)
                    Text("Search")
                        .font(Constants.Fonts.body1)
                        .foregroundColor(Constants.Colors.black)
                    Spacer()
                }
            }
            .foregroundColor(Constants.Colors.wash)
    }
}
