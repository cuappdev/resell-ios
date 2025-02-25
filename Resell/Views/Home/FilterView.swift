//
//  FilterView.swift
//  Resell
//
//  Created by Charles Liggins on 2/24/25.
//

import SwiftUI

struct FilterView: View {
    
    @State var presentPopup = false

    var body: some View {
        ZStack{
            VStack{
                Text("Filters")
                    .font(.custom("Rubik-Medium", size: 22))
                Divider()
                HStack(spacing: 180) {
                    Text("Sort by")
                        .font(.custom("Rubik-Medium", size: 20))
                    
                    Button{
                        presentPopup.toggle()
                    } label: {
                        
                        Text("Any")
                            .font(.custom("Rubik-Regular", size: 20))
                            .foregroundStyle(.gray)
                        
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.gray)
                            .padding(.leading, -2)
                    }
                }.padding(.top, 12)
                
                Divider()
                    .frame(width: 344, height: 1)
                    .padding(.top, 12)
                VStack(alignment: .leading){
                    Text("Price Range")
                        .font(.custom("Rubik-Medium", size: 20))
                    
                    Text("Any")
                        .font(.custom("Rubik-Regular", size: 17))
                        
                }
            }
            
            if presentPopup {
                sortByView
                    .offset(x: 68, y: 140)
                    .onTapGesture {
                        presentPopup.toggle()
                    }
            }
        }
    }
}

var sortByView: some View {
    
    VStack(alignment: .leading){
        Text("Any")
            .font(.system(size: 17))
        Divider()
        
        Text("Newly listed")
            .font(.system(size: 17))
        Divider()
        
        Text("Price: High to Low")
            .font(.system(size: 17))
        Divider()
        
        Text("Price: Low to High")
            .font(.system(size: 17))
    }
    .padding(.leading, 16)
    
    .frame(width: 171, height: 192)
    .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(Color.white, lineWidth: 1)
        )
        .shadow(color: Color.gray.opacity(0.3), radius: 5, x: 0, y: 2)

}

#Preview {
    FilterView()
}
