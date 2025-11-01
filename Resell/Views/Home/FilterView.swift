//
//  FilterView.swift
//  Resell
//
//  Created by Charles Liggins on 2/24/25.
//

import SwiftUI

struct FilterView: View {
    
    @State var presentPopup = false
    @State private var lowValue: Double = 0
    @State private var highValue: Double = 1000

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
                    VStack{
                    Text("Price Range")
                        .font(.custom("Rubik-Medium", size: 20))
                        
                    
                    // instead of any this should read the value of the slider
                    
                    if lowValue == 0 && highValue == 1000 {
                        Text("Any")
                            .font(.custom("Rubik-Regular", size: 20))
                            .foregroundStyle(.gray)
                    } else if lowValue == 0 {
                        Text("Up to $\(Int(highValue))")
                            .font(.custom("Rubik-Regular", size: 20))
                            .foregroundStyle(.gray)
                        
                    } else if highValue == 1000 {
                        Text("\(Int(lowValue)) +")
                            .font(.custom("Rubik-Regular", size: 20))
                            .foregroundStyle(.gray)
                        
                    } else {
                        Text("$\(Int(lowValue)) to $\(Int(highValue))")
                            .font(.custom("Rubik-Regular", size: 20))
                            .foregroundStyle(.gray)
                        }
                    }
                    .padding(.leading, 40)
                    
                    // SLIDER
                    RangeSlider(lowValue: $lowValue, highValue: $highValue, range: 0...1000)
                            .padding()

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



struct RangeSlider: View {
    @Binding var lowValue: Double
    @Binding var highValue: Double
    let range: ClosedRange<Double>
    let step: Double = 5 // Define the step value
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 360, height: 8)
                    .cornerRadius(4)
                
                
                HStack(spacing: 0) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(radius: 4)
                        .offset(x: CGFloat(self.lowValue - self.range.lowerBound) / CGFloat(self.range.upperBound - self.range.lowerBound) * geometry.size.width)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newValue = Double(value.location.x / geometry.size.width) * (self.range.upperBound - self.range.lowerBound) + self.range.lowerBound
                                    let steppedValue = round(newValue / self.step) * self.step
                                    self.lowValue = min(max(steppedValue, self.range.lowerBound), self.highValue - self.step)
                                }
                        )
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(radius: 4)
                        .offset(x: CGFloat(self.highValue - self.range.lowerBound) / CGFloat(self.range.upperBound - self.range.lowerBound) * geometry.size.width - 48)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newValue = Double(value.location.x / geometry.size.width) * (self.range.upperBound - self.range.lowerBound) + self.range.lowerBound
                                    let steppedValue = round(newValue / self.step) * self.step
                                    self.highValue = max(min(steppedValue, self.range.upperBound), self.lowValue + self.step)
                                }
                        )
                }
            }
        }
        .frame(height: 44)
    }
}

#Preview {
    FilterView()
}
