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

    let label: String

    var maxCharacters: Int?
    var frameHeight: CGFloat = 40
    var isMultiLine: Bool = false
    var placeholder: String = ""

    @Binding var text: String

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(Constants.Fonts.title1)
                .foregroundStyle(Constants.Colors.black)

            if isMultiLine {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(Constants.Fonts.body2)
                            .foregroundColor(Constants.Colors.secondaryGray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }

                    TextEditor(text: $text)
                        .font(Constants.Fonts.body2)
                        .foregroundColor(Constants.Colors.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .scrollContentBackground(.hidden)
                        .background(Constants.Colors.wash)
                        .cornerRadius(10)
                        .frame(height: frameHeight)
                        .onChange(of: text) { newText in
                            if let maxCharacters = maxCharacters, newText.count > maxCharacters {
                                text = String(newText.prefix(maxCharacters))
                            }
                        }
                }
            } else {
                TextField(placeholder, text: $text)
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.black)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(height: frameHeight, alignment: .center)
                    .background(Constants.Colors.wash)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onChange(of: text) { newText in
                        if let maxCharacters = maxCharacters, newText.count > maxCharacters {
                            text = String(newText.prefix(maxCharacters))
                        }
                    }
                    .onSubmit {
                        UIApplication.shared.endEditing()
                    }
            }
        }
    }

}
