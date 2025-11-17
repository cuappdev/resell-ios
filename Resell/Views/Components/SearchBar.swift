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
        RoundedRectangle(cornerRadius: 40)
            .frame(width: 309, height: 43)
            .overlay {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.black)
                        .padding(.leading, 16)
                    
                    if isEditable {
                        TextField(placeholder, text: textBinding)
                            .font(Constants.Fonts.body1)
                            .foregroundColor(Constants.Colors.black)
                        
                        if !textBinding.wrappedValue.isEmpty {
                            Button(action: {
                                textBinding.wrappedValue = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Constants.Colors.stroke)
                            }
                            .padding(.trailing, 8)
                        }
                    } else {
                        Text(placeholder)
                            .font(Constants.Fonts.body1)
                            .foregroundColor(Constants.Colors.black)
                    }
                    
                    Spacer()
                }
            }
            .foregroundColor(Constants.Colors.wash)
    }
}
