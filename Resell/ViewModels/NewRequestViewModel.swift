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
    @Published var isLoading: Bool = false
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
        Task {
            isLoading = true

            do {
                guard let userID = UserSessionManager.shared.userID else {
                    UserSessionManager.shared.logger.error("Error in NewRequestViewModel.createNewRequest: userID not found")
                    return
                }

                let requestBody = RequestBody(title: titleText, description: descriptionText, userId: userID)
                let request = try await NetworkManager.shared.postRequest(request: requestBody)

                isLoading = false
            } catch {
                NetworkManager.shared.logger.error("Error in NewRequestViewModel.createNewRequest: \(error.localizedDescription)")
            }
        }
    }
}

