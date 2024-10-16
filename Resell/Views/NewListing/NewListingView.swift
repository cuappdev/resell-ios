//
//  NewListingView.swift
//  Resell
//
//  Created by Richie Sun on 10/9/24.
//

import PhotosUI
import SwiftUI
import UIKit

struct NewListingView: View {

    // MARK: - Properties

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var mainViewModel: MainViewModel

    @StateObject private var viewModel = NewListingViewModel()

    var selectedIndex: Int = 0

    // MARK: - UI

    var body: some View {
        if viewModel.isDetailsView {
            NewListingDetailsView()
                .environmentObject(viewModel)
                .transition(.move(edge: .trailing))
        } else {
            NewListingImagesView()
                .environmentObject(viewModel)
        }
    }
}
