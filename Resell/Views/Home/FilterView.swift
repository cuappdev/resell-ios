//
//  FilterView.swift
//  Resell
//
//  Created by Charles Liggins on 2/24/25.
//

import SwiftUI
import Flow

// TODO: Implement Apply Filters button.
struct FilterView: View {
    @Binding var isPresented: Bool
    @State var presentPopup = false
    @EnvironmentObject var filtersVM: FiltersViewModel  // Change to @EnvironmentObject

    private var categories : [String] = ["Clothing", "Books", "School", "Electronics", "Handmade", "Sports & Outdoors", "Other"]
    private var conditions : [String] = ["Gently Used", "Worn", "Never Used"]
    
    let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
    
    let gridItem = GridItem(.adaptive(minimum: 100), spacing: 10)

    let home : Bool
    
    init(home: Bool, isPresented: Binding<Bool>) {
        self.home = home
        _isPresented = isPresented
    }
    
    @StateObject private var homeViewModel = HomeViewModel.shared
    
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
                if home {
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
                                        if filtersVM.categoryFilters.contains(category){
                                            filtersVM.categoryFilters.remove(category)
                                        } else {
                                            filtersVM.categoryFilters.insert(category)
                                        }
                                    } label: {
                                        if filtersVM.categoryFilters.contains(category) {
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
                    
                    if !home {
                        Spacer()
                    }
                }
                .padding(.trailing, 32)
                
                HStack{
                    Button {
                        filtersVM.resetFilters(homeViewModel: homeViewModel)
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
                        // MARK: This should wait for the above request to complete
                        isPresented = false
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
        }.frame(width: 414, height: home ? 786 : 686)
        .background(Color.white)
        // TODO: Add border to filter view
    }
    
    struct SortByView: View {
        @Binding var selectedSort: SortOption?

        let sortOptions = SortOption.allCases
        
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


enum SortOption: String, CaseIterable, Identifiable {
    case any = "Any"
    case newlyListed = "Newly listed"
    case priceHighToLow = "Price: High to Low"
    case priceLowToHigh = "Price: Low to High"
    
    var id: String { rawValue }
    
    var title: String { rawValue }
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

