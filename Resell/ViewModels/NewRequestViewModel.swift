//
//  NewRequestViewModel.swift
//  Resell
//
//  Created by Richie Sun on 10/16/24.
//

import PhotosUI
import SwiftUI

@MainActor
class NewRequestViewModel: ObservableObject {

    // MARK: - Properties

    @Published var didShowPriceInput: Bool = false
    @Published var isMinText: Bool = true

    @Published var descriptionText: String = ""
    @Published var priceTextMin: String = ""
    @Published var priceTextMax: String = ""
    @Published var titleText: String = ""

    // MARK: - Functions

    func checkInputIsValid() -> Bool {
        return !(descriptionText.cleaned().isEmpty || priceTextMin.cleaned().isEmpty || priceTextMax.cleaned().isEmpty || titleText.cleaned().isEmpty) && (Double(priceTextMax.replacingOccurrences(of: ",", with: "")) ?? 0 > Double(priceTextMin.replacingOccurrences(of: ",", with: "")) ?? 0)
    }

    func createNewRequest() {
        // TODO: Backend Call
    }
}

