//
//  SearchBar.swift
//  Resell
//
//  Created by Charles Liggins on 4/27/25.
//

import SwiftUI

struct SearchBar: View {
    var text: Binding<String>?
    var placeholder: String = "Search"
    var isEditable: Bool = false
    
    @State private var internalText: String = ""
    
    private var textBinding: Binding<String> {
        text ?? $internalText
    }
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Constants.Colors.secondaryGray)

            if isEditable {
                ZStack(alignment: .leading) {
                   if textBinding.wrappedValue.isEmpty {
                       Text(placeholder)
                           .font(Constants.Fonts.body1)
                           .foregroundColor(Constants.Colors.secondaryGray) // Use a visible gray
                   }

                   TextField("", text: textBinding)
                       .font(Constants.Fonts.body1)
                       .foregroundColor(Constants.Colors.black)
               }

                if !textBinding.wrappedValue.isEmpty {
                    Button(action: {
                        textBinding.wrappedValue = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Constants.Colors.stroke)
                    }
                }
            } else {
                Text(placeholder)
                    .font(Constants.Fonts.body1)
                    .foregroundColor(Constants.Colors.black)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: .capsule)
    }
}
