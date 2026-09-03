//
//  CategoriesView.swift
//  Resell
//
//  Created by Andrew Gao on 9/3/26.
//

import SwiftUI

struct CategoriesView: View {

    @EnvironmentObject var router: Router

    var body: some View {
        VStack(alignment: .leading) {
            Text("Shop By Category")
                .font(Constants.Fonts.h2)
                .foregroundStyle(Constants.Colors.black)
                .padding(.leading, Constants.Spacing.horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top) {
                    ForEach(Constants.filters.filter { $0.color != nil }, id: \.id) { filter in
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
                .padding(.leading, Constants.Spacing.horizontalPadding)
                .padding(.vertical, 1)
            }
        }
    }
}
