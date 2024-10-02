//
//  MainViewModel.swift
//  Resell
//
//  Created by Richie Sun on 9/11/24.
//

import SwiftUI

@MainActor
class MainViewModel: ObservableObject {

    // MARK: - Properties

    @Published var userDidLogin: Bool = false

}
