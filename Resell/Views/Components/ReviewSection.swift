//
//  ReviewSection.swift
//  Resell
//
//  Created by Charles Liggins on 12/30/25.
//

import SwiftUI

struct ReviewSection: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .stroke(.gray, lineWidth: 1)
                .frame(width: 366, height: 118)
                

            Text("No Reviews Yet")
                .font(Constants.Fonts.body2)
                .foregroundColor(.gray)
        }
    }
}
