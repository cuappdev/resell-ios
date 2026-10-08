//
//  FilterView.swift
//  Resell
//
//  Created by Charles Liggins on 2/24/25.
//

import SwiftUI
import Flow

struct FilterView: View {

    // MARK: - Properties

    @Binding var isPresented: Bool
    @State var presentPopup = false
    @EnvironmentObject var filtersVM: FiltersViewModel

    private let categories: [String] = Constants.productCategories.map(\.title)
    private let conditions: [String] = ["Gently Used", "Worn", "Never Used"]

    let home: Bool

    init(home: Bool, isPresented: Binding<Bool>) {
        self.home = home
        _isPresented = isPresented
    }

    @ObservedObject private var homeViewModel = HomeViewModel.shared

    // MARK: - UI

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            ZStack {
                VStack(spacing: 0) {
                    header

                    Divider()

                    ScrollView {
                        filterSections
                    }

                    Spacer()

                    footerButtons
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
    }

    private var header: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 10)
                .frame(width: 66, height: 6)
                .foregroundStyle(Constants.Colors.filterGray)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Text("Filters")
                .font(.custom("Rubik-Medium", size: 22))
                .foregroundStyle(.black)
                .padding(.vertical, 20)
        }
    }

    private var filterSections: some View {
        VStack(alignment: .leading, spacing: 0) {
            sortBySection
            priceRangeSection

            if home {
                productCategorySection
            }

            conditionSection
        }
        .padding(.horizontal, 28)
    }

    @ViewBuilder
    private var sortBySection: some View {
        HStack {
            sectionTitle("Sort by")

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
    }

    @ViewBuilder
    private var priceRangeSection: some View {
        HStack {
            sectionTitle("Price Range")

            Spacer()

            priceRangeLabel
                .font(.custom("Rubik-Regular", size: 20))
                .foregroundStyle(.gray)
        }
        .padding(.bottom, 8)

        RangeSlider(lowValue: $filtersVM.lowValue, highValue: $filtersVM.highValue, range: 0...1000)
            .padding(.trailing, -28)
    }

    @ViewBuilder
    private var priceRangeLabel: some View {
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

    @ViewBuilder
    private var productCategorySection: some View {
        Divider()
            .padding(.top, 4)
            .padding(.bottom, 12)

        sectionTitle("Product Category")
            .padding(.bottom, 8)

        HFlow {
            ForEach(categories, id: \.self) { category in
                filterChip(category, isSelected: filtersVM.categoryFilters.contains(category)) {
                    toggle(category, in: &filtersVM.categoryFilters)
                }
            }
        }

        Divider()
            .padding(.vertical, 12)
    }

    @ViewBuilder
    private var conditionSection: some View {
        sectionTitle("Condition")
            .padding(.bottom, 8)
            .padding(.top, home ? 0 : 12)

        HStack {
            ForEach(conditions, id: \.self) { condition in
                filterChip(condition, isSelected: filtersVM.conditionFilters.contains(condition)) {
                    toggle(condition, in: &filtersVM.conditionFilters)
                }
            }
        }
    }

    private var footerButtons: some View {
        HStack {
            resetButton

            Spacer()

            applyFiltersButton
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 16)
    }

    private var resetButton: some View {
        Button {
            filtersVM.resetFilters(homeViewModel: homeViewModel)
        } label: {
            Text("Reset")
                .font(.custom("Rubik-Medium", size: 20))
                .foregroundStyle(.black)
        }
    }

    private var applyFiltersButton: some View {
        Button {
            Task {
                try await filtersVM.applyFilters(homeViewModel: homeViewModel)
                isPresented = false
            }
        } label: {
            Text("Apply filters")
                .font(.custom("Rubik-Medium", size: 20))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(!filtersVM.hasActiveFilters ? Constants.Colors.resellPurple.opacity(0.4) : Constants.Colors.resellPurple)
                .cornerRadius(20)
        }
        .disabled(!filtersVM.hasActiveFilters)
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.custom("Rubik-Medium", size: 20))
            .foregroundStyle(.black)
    }

    private func filterChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Constants.Fonts.title3)
                .foregroundStyle(isSelected ? Constants.Colors.resellPurple : Constants.Colors.black)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Constants.Colors.resellPurple : Constants.Colors.filterGray, lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Constants.Colors.purpleWash : Color.white)
                )
        )
    }

    // MARK: - Helpers

    private func toggle(_ value: String, in filters: inout Set<String>) {
        if filters.contains(value) {
            filters.remove(value)
        } else {
            filters.insert(value)
        }
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
