//
//  FilterView.swift
//  Resell
//
//  Created by Charles Liggins on 2/24/25.
//

import SwiftUI
import Flow

// TODO: Implement Apply Filters button.
    // use a set to store some encoding of the filters being currently applied
    // why? quick removal + add operations
    // add/remove when a filter button is toggled
    // when apply filter button is clicked, iterate through the set and apply each filter
    // Applied filters don't persist...
struct FilterView: View {
    
    @State var presentPopup = false
    
    @EnvironmentObject var filtersVM: FiltersViewModel
    @StateObject private var homeViewModel = HomeViewModel.shared

    private var categories : [String] = ["Clothing", "Books", "School", "Electronics", "Handmade", "Sports & Outdoors", "Other"]
    private var conditions : [String] = ["Gently Used", "Worn", "Never Used"]
    
    let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
    
    let gridItem = GridItem(.adaptive(minimum: 100), spacing: 10)

    let home : Bool
    
    init(home: Bool) {
        self.home = home
    }
    
    var body: some View {
        ZStack{
            VStack{
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: 66, height: 6)
                    .foregroundStyle(Constants.Colors.filterGray)
                    .padding(.bottom, 16)
                
                Text("Filters")
                    .font(.custom("Rubik-Medium", size: 22))
                    .foregroundStyle(.black)
                Divider()
                HStack(spacing: 120) {
                    Text("Sort by")
                        .font(.custom("Rubik-Medium", size: 20))
                        .foregroundStyle(.black)

                    
                    Button{
                        presentPopup.toggle()
                    } label: {
                        Text("\(filtersVM.selectedSort?.title ?? "Any")")
                            .font(.custom("Rubik-Regular", size: 20))
                            .foregroundStyle(.gray)
                        
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.gray)
                            .padding(.leading, -2)
                    }
                }.padding(.top, 12)
                    .frame(width: 320)
                
                Divider()
                    .frame(width: 344, height: 1)
                    .padding(.top, 12)
                
                VStack(alignment: .leading){
                    VStack{
                    Text("Price Range")
                        .font(.custom("Rubik-Medium", size: 20))
                        .padding(.leading, 28)
                        .padding(.bottom, 8)

                                        
                        if filtersVM.lowValue == 0 && filtersVM.highValue == 1000 {
                        Text("Any")
                            .font(.custom("Rubik-Regular", size: 20))
                            .foregroundStyle(.gray)
                            .padding(.trailing, 52)
                        

                        } else if filtersVM.lowValue == 0 {
                            Text("Up to $\(Int(filtersVM.highValue))")
                            .font(.custom("Rubik-Regular", size: 20))
                            .foregroundStyle(.gray)
                        
                        } else if filtersVM.highValue == 1000 {
                            Text("$\(Int(filtersVM.lowValue)) +")
                            .font(.custom("Rubik-Regular", size: 20))
                            .foregroundStyle(.gray)
                            .padding(.trailing, filtersVM.lowValue > 99 ? 24 : 36)

                        
                    } else {
                        Text("$\(Int(filtersVM.lowValue)) to $\(Int(filtersVM.highValue))")
                            .font(.custom("Rubik-Regular", size: 20))
                            .foregroundStyle(.gray)
                        }
                    }
                    
                    // SLIDER
                    RangeSlider(lowValue: $filtersVM.lowValue, highValue: $filtersVM.highValue, range: 0...1000)
                        .padding(.leading, 28)
                        .offset(y: -20)
                    
                    HStack{
                        Text("Items On Sale")
                            .font(.custom("Rubik-Regular", size: 20))
                            .foregroundStyle(.gray)
                            .padding(.leading, 28)
                        
                        Spacer()
                        
                        Button {
                            filtersVM.showSale.toggle()
                        } label: {
                            Image(filtersVM.showSale ? "toggle-set" : "toggle" )
                        }.padding(.trailing, 28)
                        
                        
                    }
                    .offset(y: -28)
                }
                if home{
                    Divider()
                        .frame(width: 344, height: 1)
                        .offset(y: -16)
                    
                    
                    VStack{
                        Text("Product Category")
                            .font(.custom("Rubik-Medium", size: 20))
                            .padding(.bottom, 8)
                            .padding(.trailing, 72)
                            .foregroundStyle(.black)
                        
                        
                        HFlow {
                            ForEach(categories, id: \.self) { category in
                                HStack {
                                    Button {
                                        // TODO: change logic for uppercasing...
                                        if filtersVM.categoryFilters.contains(category.uppercased()){
                                            filtersVM.categoryFilters.remove(category.uppercased())
                                        } else {
                                            filtersVM.categoryFilters.insert(category.uppercased())
                                        }
                                    } label: {
                                        if filtersVM.categoryFilters.contains(category.uppercased()) {
                                            HStack{
                                                Text(category)
                                                    .font(.custom("Rubik-Medium", size: 14))
                                                    .foregroundStyle(Constants.Colors.resellPurple)
                                                
                                                Image(systemName: "xmark")
                                                    .font(.custom("Rubik-Medium", size: 14))
                                                    .foregroundStyle(Constants.Colors.resellPurple)
                                            }
                                        } else {
                                            Text(category)
                                                .font(.custom("Rubik-Medium", size: 14))
                                                .foregroundStyle(Color.black)
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(filtersVM.categoryFilters.contains(category) ? Constants.Colors.resellPurple : Constants.Colors.filterGray, lineWidth: 1)
                                        
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(filtersVM.categoryFilters.contains(category) ? Constants.Colors.purpleWash : Color.white)
                                            )
                                    )
                                }
                            }
                        }
                        .frame(width: 320, alignment: .leading)
                        .offset(x: 36)
                    }
                    .padding(.trailing, 96)
                    
                    Divider()
                        .frame(width: 344, height: 1)
                        .offset(y: 16)
                    
                }
                
                VStack{
                    Text("Condition")
                        .font(.custom("Rubik-Medium", size: 20))
                        .padding(.trailing, 232)
                        .padding(.bottom, 8)
                        .padding(.top, home ? 28 : 0)
                        .foregroundStyle(.black)


                    HStack {
                        ForEach(conditions, id: \.self){ condition in
                            Button {
                                // toggle condition, if true, add to set, if false, remove from set
                                if filtersVM.conditionFilters.contains(condition){
                                    filtersVM.conditionFilters.remove(condition)
                                } else {
                                    filtersVM.conditionFilters.insert(condition)
                                }
                            } label: {
                                if filtersVM.conditionFilters.contains(condition) {
                                    HStack{
                                        Text(condition)
                                            .font(.custom("Rubik-Medium", size: 14))
                                            .foregroundStyle(Constants.Colors.resellPurple)
                                        
                                        Image(systemName: "xmark")
                                            .font(.custom("Rubik-Medium", size: 14))
                                            .foregroundStyle(Constants.Colors.resellPurple)
                                    }
                                } else {
                                    Text(condition)
                                        .font(.custom("Rubik-Medium", size: 14))
                                        .foregroundStyle(Color.black)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                
                                    .stroke(filtersVM.conditionFilters.contains(condition) ? Constants.Colors.resellPurple : Constants.Colors.filterGray, lineWidth: 1)
                                    
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(filtersVM.conditionFilters.contains(condition) ? Constants.Colors.purpleWash : Color.white)
                                        )
                            )
                        }
                       
                    }
                    .frame(width: 320, alignment: .leading)
                    .padding(.leading, -8)
                }
                .padding(.trailing, 32)
                
                HStack{
                    Button {
                        filtersVM.categoryFilters.removeAll()
                        filtersVM.conditionFilters.removeAll()
                    } label: {
                        Text("Reset")
                            .font(.custom("Rubik-Medium", size: 20))
                            .padding(.leading, 40)
                            .foregroundStyle(.black)
                    }
                    
                    Spacer()
                    
                    Button{
                        Task {
                            try await filtersVM.applyFilters(homeViewModel: homeViewModel)
                        }
                    } label: {
                            Text("Apply filters")
                                .font(.custom("Rubik-Medium", size: 20))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(filtersVM.categoryFilters.isEmpty && filtersVM.conditionFilters.isEmpty ? Constants.Colors.resellPurple.opacity(0.4) : Constants.Colors.resellPurple)
                                .cornerRadius(20)
                    }
                    .padding(.trailing, 40)
                }
                .padding(.top, 32)
            }
            
            if presentPopup {
                SortByView(selectedSort: $filtersVM.selectedSort)
                    .offset(x: 88, y: home ? -142 : 0)
                    .onTapGesture {
                        presentPopup.toggle()
                    }
            }
        }.frame(width: 414, height: 786)
            .background(Color.white)
    }
    
    struct SortByView: View {
        @Binding var selectedSort: SortOption?

        let sortOptions = [
            SortOption(title: "Any"),
            SortOption(title: "Newly listed"),
            SortOption(title: "Price: High to Low"),
            SortOption(title: "Price: Low to High")
        ]
        
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(sortOptions) { option in
                    Button(action: {
                        selectedSort = option

                        
                    }) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(option.title)
                                .font(.system(size: 17, weight: selectedSort == option ? .bold : .regular))
                                .foregroundColor(.black)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if option != sortOptions.last {
                                Divider()
                            }
                        }
                        
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(Color.white)
            .frame(width: 171)
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            }
    }
}


// Implement Reset Button
func reset(){}
struct SortOption: Identifiable, Equatable {
    let id = UUID()
    let title: String
}


struct RangeSlider: View {
    @Binding var lowValue: Double
    @Binding var highValue: Double
    let range: ClosedRange<Double>
    let step: Double = 5 // Define the step value
    
    // Track width constant
    private let trackWidth: CGFloat = 344
    private let handleDiameter: CGFloat = 14
    
    // Calculate position from value
    private func position(for value: Double) -> CGFloat {
        let percentage = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(percentage) * (trackWidth - handleDiameter)
    }
    
    // Calculate value from position
    private func value(for position: CGFloat) -> Double {
        let percentage = Double(position) / Double(trackWidth - handleDiameter)
        let value = percentage * (range.upperBound - range.lowerBound) + range.lowerBound
        return round(value / step) * step
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Constants.Colors.resellPurple.opacity(0.2))
                    .frame(width: trackWidth, height: 4)
                    .cornerRadius(4)
                
                // Low handle
                Circle()
                    .fill(Color.white)
                    .frame(width: handleDiameter, height: handleDiameter)
                    .shadow(radius: 4)
                    .position(x: position(for: lowValue) + handleDiameter/2, y: geometry.size.height/2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPosition = min(max(0, value.location.x - handleDiameter/2), position(for: highValue) - handleDiameter)
                                let newValue = self.value(for: newPosition)
                                // Ensure minimum distance between handles
                                if newValue <= highValue - step {
                                    lowValue = newValue
                                }
                            }
                    )
                
                // High handle
                Circle()
                    .fill(Color.white)
                    .frame(width: handleDiameter, height: handleDiameter)
                    .shadow(radius: 4)
                    .position(x: position(for: highValue) + handleDiameter/2, y: geometry.size.height/2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPosition = min(max(position(for: lowValue) + handleDiameter, value.location.x - handleDiameter/2), trackWidth - handleDiameter)
                                let newValue = self.value(for: newPosition)
                                // Ensure minimum distance between handles
                                if newValue >= lowValue + step {
                                    highValue = newValue
                                }
                            }
                    )
            }
        }
        .frame(height: 44)
    }
}

#Preview {
    FilterView(home: true)
}
