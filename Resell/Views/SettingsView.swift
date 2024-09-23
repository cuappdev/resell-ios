//
//  SettingsView.swift
//  Resell
//
//  Created by Richie Sun on 9/23/24.
//

import SwiftUI

struct SettingsView: View {

    // MARK: - Properties

    @Environment(\.dismiss) var dismiss

    // MARK: - UI

    var body: some View {
        VStack {
            Text("SettingsView")
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton(dismiss: self.dismiss)
            }

            ToolbarItem(placement: .principal) {
                Text("Settings")
                    .font(Constants.Fonts.h3)
            }
        }
    }
}
