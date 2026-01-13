//
//  AvailabilitySettingsView.swift
//  Resell
//
//  Created by Charles Liggins on 1/12/26.
//
import SwiftUI

struct AvailabilitySettingsView: View {
    var body: some View {
        VStack {
            Text("Hello, World!")
        }
        .toolbar() {
            ToolbarItem(placement: .principal) {
                Text("Availability")
                    .foregroundStyle(.black)
            }
        }
    }
}
