//
//  CategoriesView.swift
//  Resell
//
//  Created by Andrew Gao on 9/3/26.
//

import SwiftUI

/// "Shop By Category" row: one circular button per product category, each
/// opening that category's browse screen.
struct CategoriesView: View {

    // MARK: - Properties

    @EnvironmentObject private var router: Router

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading) {
            Text("Shop By Category")
                .font(Constants.Fonts.h2)
                .foregroundStyle(Constants.Colors.black)
                .padding(.leading, Constants.Spacing.horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top) {
                    ForEach(Constants.productCategories, id: \.id) { filter in
                        categoryButton(for: filter)
                    }
                }
                .padding(.leading, Constants.Spacing.horizontalPadding)
                .padding(.vertical, 1)
            }
        }
    }

    private func categoryButton(for filter: FilterCategory) -> some View {
        VStack {
            CircularFilterButton(filter: filter) {
                router.push(.detailedFilter(filter))
            }

            Text(filter.title)
                .font(Constants.Fonts.title4)
                .frame(width: 80)
                .multilineTextAlignment(.center)
                .foregroundStyle(Constants.Colors.black)
        }
        .padding(.trailing, 30)
    }
}
