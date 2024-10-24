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

    @Published var reportDetailsText: String = "" {
        didSet {
            if reportDetailsText.count > 1000 {
                reportDetailsText = String(reportDetailsText.prefix(1000))
            }
        }
    }

    // TODO: Add Logic to change this later
    @Published var reportType: String = "Post"
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

    func clear() {
        didShowPopup = false
        reportDetailsText = ""
        selectedOption = ""
    }

}
