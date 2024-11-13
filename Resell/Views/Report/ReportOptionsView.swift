//
//  ReportOptionsView.swift
//  Resell
//
//  Created by Richie Sun on 10/19/24.
//

import SwiftUI

struct ReportOptionsView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var viewModel: ReportViewModel

    // MARK: - UI

    var body: some View {
        VStack {
            Text("Why do you want to report this \(viewModel.reportType)?")
                .font(Constants.Fonts.title1)
                .foregroundStyle(Constants.Colors.black)
                .padding(.top, 32)

            ForEach(viewModel.reportOptions, id: \.self) { option in
                Button {
                    viewModel.selectedOption = option
                    router.push(.reportDetails)
                } label: {
                    reportOptionsRow(option: option)
                }
            }

            Spacer()
        }
        .background(Constants.Colors.white)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Report \(viewModel.reportType)")
                    .font(Constants.Fonts.h3)
                    .foregroundStyle(Constants.Colors.black)
            }
        }
        .onAppear {
            viewModel.clear()
        }
    }

    private func reportOptionsRow(option: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(option)
                .font(Constants.Fonts.body1)
                .foregroundStyle(Constants.Colors.black)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(Constants.Colors.black)
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .padding(.vertical, 18.5)
        .background(Color.white)
    }
}
