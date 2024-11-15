//
//  ReportDetailsView.swift
//  Resell
//
//  Created by Richie Sun on 10/19/24.
//

import SwiftUI

struct ReportDetailsView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: ReportViewModel

    // MARK: - UI

    var body: some View {
        VStack {
            Text(viewModel.selectedOption)
                .font(Constants.Fonts.title1)
                .foregroundStyle(Constants.Colors.black)
                .padding(.top, 32)

            Text("Please provide more details about the \(viewModel.reportType)")
                .font(Constants.Fonts.body2)
                .foregroundStyle(Constants.Colors.secondaryGray)
                .padding(.top, 16)

            TextEditor(text: $viewModel.reportDetailsText)
                .font(Constants.Fonts.body2)
                .foregroundColor(Constants.Colors.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .scrollContentBackground(.hidden)
                .frame(height: 180)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Constants.Colors.secondaryGray)
                }

            Spacer()

            PurpleButton(isActive: !viewModel.reportDetailsText.cleaned().isEmpty,text: "Submit") {
                router.push(.reportConfirmation)
            }
            .padding(.bottom, Constants.Spacing.horizontalPadding)
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .background(Constants.Colors.white)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Report \(viewModel.reportType)")
                    .font(Constants.Fonts.h3)
                    .foregroundStyle(Constants.Colors.black)
            }
        }
        .endEditingOnTap()
    }
}
