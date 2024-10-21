//
//  ReportViewModel.swift
//  Resell
//
//  Created by Richie Sun on 10/19/24.
//

import SwiftUI

@MainActor
class ReportViewModel: ObservableObject {

    // MARK: - Properties

    @Published var didShowPopup: Bool = false
    @Published var didSubmitReport: Bool = false
    @Published var isDetailsView: Bool = false

    @Published var reportDetailsText: String = "" {
        didSet {
            if reportDetailsText.count > 1000 {
                reportDetailsText = String(reportDetailsText.prefix(1000))
            }
        }
    }

    @Published var reportType: String = ""
    @Published var selectedOption: String = ""

    // TODO: - Replace with actual user name
    var username: String = "Justin_Guo"

    var reportOptions = [
        "Fraudulent behavior",
        "Sale of Illegal items",
        "Hate speech or symbols",
        "Bullying or harassment",
        "Sexual misconduct or nudity",
        "Unauthorized use of intellectual property",
        "Other"
    ]

    // MARK: - Functions

    func reportMessage() {
        // TODO: Backend Report Call
    }

    func reportPost() {
        // TODO: Backend Report Call
    }

    func reportUser() {
        // TODO: Backend Report Call
    }

}