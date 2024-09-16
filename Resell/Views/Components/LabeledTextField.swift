//
//  LabeledTextField.swift
//  Resell
//
//  Created by Richie Sun on 9/16/24.
//

import SwiftUI

/// Customizable Resell text field
struct LabeledTextField: View {

    // MARK: - Properties
    
    var frameHeight: CGFloat = 40
    var label: String
    var isMultiLine: Bool = false
    var maxCharacters: Int?

    @State private var text: String = ""

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(Constants.Fonts.title1)

            TextField("", text: $text, axis: isMultiLine ? .vertical : .horizontal)
                .font(Constants.Fonts.body2)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(height: frameHeight, alignment: isMultiLine ? .top : .center)
                .background(Constants.Colors.wash)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onChange(of: text) { newText in
                    if let maxCharacters = maxCharacters, newText.count > maxCharacters {
                        text = String(newText.prefix(maxCharacters))
                    }
                }
        }
    }
}

struct LabeledTextField_Previews: PreviewProvider {
    static var previews: some View {
        LabeledTextField(frameHeight: 40, label: "Label", maxCharacters: 100)
    }
}
