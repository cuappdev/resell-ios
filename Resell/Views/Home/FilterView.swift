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

    let home : Bool
    
    init(home: Bool, isPresented: Binding<Bool>) {
        self.home = home
        _isPresented = isPresented
    }
    
    @ObservedObject private var homeViewModel = HomeViewModel.shared
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            ZStack {
                VStack(spacing: 0) {
                    // Drag handle — centered
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 66, height: 6)
                        .foregroundStyle(Constants.Colors.filterGray)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    
                    // Title — centered
                    Text("Filters")
                        .font(.custom("Rubik-Medium", size: 22))
                        .foregroundStyle(.black)
                        .padding(.vertical, 20)
                    
                    Divider()
                    
                    // Scrollable content
                    ScrollView {
                        // Left-aligned content sections
                        VStack(alignment: .leading, spacing: 0) {
                        
                        // MARK: - Sort By
                        
                        HStack {
                            Text("Sort by")
                                .font(.custom("Rubik-Medium", size: 20))
                                .foregroundStyle(.black)
                            
                            Spacer()
                            
                            Button {
                                presentPopup.toggle()
                            } label: {
                                HStack(spacing: 2) {
                                    Text("\(filtersVM.selectedSort?.title ?? "Any")")
                                        .font(.custom("Rubik-Regular", size: 20))
                                        .foregroundStyle(.gray)
                                    
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(.gray)
                                }
                            }
                        }
                        .padding(.vertical, 24)
                        
                        Divider()
                            .padding(.bottom, 16)
                        
                        // MARK: - Price Range
                        
                        HStack {
                            Text("Price Range")
                                .font(.custom("Rubik-Medium", size: 20))
                                .foregroundStyle(.black)
                            
                            Spacer()
                            
                            Group {
                                if filtersVM.lowValue == 0 && filtersVM.highValue == 1000 {
                                    Text("Any")
                                } else if filtersVM.lowValue == 0 {
                                    Text("Up to $\(Int(filtersVM.highValue))")
                                } else if filtersVM.highValue == 1000 {
                                    Text("$\(Int(filtersVM.lowValue)) +")
                                } else {
                                    Text("$\(Int(filtersVM.lowValue)) to $\(Int(filtersVM.highValue))")
                                }
                            }
                            .font(.custom("Rubik-Regular", size: 20))
                            .foregroundStyle(.gray)
                        }
                        .padding(.bottom, 8)
                        
                        // Slider — extend trailing to avoid clipping the 344pt track
                        RangeSlider(lowValue: $filtersVM.lowValue, highValue: $filtersVM.highValue, range: 0...1000)
                            .padding(.trailing, -28)
                        
                        
                        if home {
                            Divider()
                                .padding(.top, 4)
                                .padding(.bottom, 12)
                            
                            // MARK: - Product Category
                            
                            Text("Product Category")
                                .font(.custom("Rubik-Medium", size: 20))
                                .foregroundStyle(.black)
                                .padding(.bottom, 8)
                            
                            HFlow {
                                ForEach(categories, id: \.self) { category in
                                    HStack {
                                        Button {
                                            if filtersVM.categoryFilters.contains(category){
                                                filtersVM.categoryFilters.remove(category)
                                            } else {
                                                filtersVM.categoryFilters.insert(category)
                                            }
                                        } label: {
                                            if filtersVM.categoryFilters.contains(category) {
                                                HStack {
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
                            
                            Divider()
                                .padding(.vertical, 12)
                        }
                        
                        // MARK: - Condition
                        
                        Text("Condition")
                            .font(.custom("Rubik-Medium", size: 20))
                            .foregroundStyle(.black)
                            .padding(.bottom, 8)
                            .padding(.top, home ? 0 : 12)
                        
                        HStack {
                            ForEach(conditions, id: \.self){ condition in
                                Button {
                                    if filtersVM.conditionFilters.contains(condition){
                                        filtersVM.conditionFilters.remove(condition)
                                    } else {
                                        filtersVM.conditionFilters.insert(condition)
                                    }
                                } label: {
                                    if filtersVM.conditionFilters.contains(condition) {
                                        HStack {
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
                    }
                    .padding(.horizontal, 28)
                    } // End of ScrollView
                    
                    Spacer()
                    
                    // MARK: - Reset / Apply Buttons (Fixed at bottom)
                    
                    HStack{
                        Button {
                            filtersVM.resetFilters(homeViewModel: homeViewModel)
                        } label: {
                            Text("Reset")
                                .font(.custom("Rubik-Medium", size: 20))
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
                        .disabled(filtersVM.categoryFilters.isEmpty && filtersVM.conditionFilters.isEmpty)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                }
                
                if presentPopup {
                    SortByView(selectedSort: $filtersVM.selectedSort)
                        .offset(x: 88, y: -142)
                        .onTapGesture {
                            presentPopup.toggle()
                        }
                }
            }
        }

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
