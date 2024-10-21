//
//  ReportView.swift
//  Resell
//
//  Created by Richie Sun on 10/19/24.
//

import SwiftUI

struct ReportView: View {

    // MARK: - Properties

    @StateObject var viewModel = ReportViewModel()

    let reportType: String

    // MARK: - UI

    var body: some View {
        VStack {
            if viewModel.isDetailsView {
                if viewModel.didSubmitReport {
                    ReportConfirmationView()
                        .environmentObject(viewModel)
                        .transition(.move(edge: .trailing))
                } else {
                    ReportDetailsView()
                        .environmentObject(viewModel)
                        .transition(.move(edge: .trailing))
                }
            } else {
                ReportOptionsView()
                    .environmentObject(viewModel)
                    .background {
                        NavigationConfigurator { nc in
                            nc.setBackButtonTint()
                        }
                    }
            }
        }
        .onAppear {
            viewModel.reportType = reportType
        }
    }
}
