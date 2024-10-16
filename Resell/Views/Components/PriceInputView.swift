//
//  PriceInputView.swift
//  Resell
//
//  Created by Richie Sun on 10/16/24.
//

import SwiftUI

struct PriceInputView: View {

    // MARK: - Properties

    @Binding var price: String
    @Binding var isPresented: Bool

    let titleText: String

    // MARK: - UI

    var body: some View {
        VStack {
            Text(titleText)
                .font(Constants.Fonts.h3)
                .foregroundStyle(Constants.Colors.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Spacer()

            HStack(spacing: 12) {
                Text("$")
                    .font(.custom("Rubik-Regular", size: 48))
                    .foregroundStyle(Constants.Colors.secondaryGray)
                Text(price)
                    .font(.custom("Rubik-Regular", size: 36))
                    .foregroundStyle(Constants.Colors.black)
                    .padding(.horizontal, 16)
                    .frame(width: 150, height: 60)
                    .background(Constants.Colors.wash)
                    .clipShape(.rect(cornerRadius: 10))
            }

            Spacer()

            numberPadView

            Spacer()

            PurpleButton(isActive: isValidUSD(price), text: "Continue") {
                if isValidUSD(price) {
                    isPresented = false
                }
            }
        }
        .padding(.top, UIScreen.height < 700 ? 0 : 48)
    }

    private var numberPadView: some View {
        VStack {
            HStack {
                Spacer()

                NumericButton(title: "1", action: { appendNumber("1") })

                Spacer()

                NumericButton(title: "2", action: { appendNumber("2") })

                Spacer()

                NumericButton(title: "3", action: { appendNumber("3") })

                Spacer()
            }

            Spacer()

            HStack {
                Spacer()

                NumericButton(title: "4", action: { appendNumber("4") })

                Spacer()

                NumericButton(title: "5", action: { appendNumber("5") })

                Spacer()

                NumericButton(title: "6", action: { appendNumber("6") })

                Spacer()
            }

            Spacer()

            HStack {
                Spacer()

                NumericButton(title: "7", action: { appendNumber("7") })

                Spacer()

                NumericButton(title: "8", action: { appendNumber("8") })

                Spacer()

                NumericButton(title: "9", action: { appendNumber("9") })

                Spacer()
            }

            Spacer()

            HStack {
                Spacer()

                NumericButton(title: ".", action: { appendNumber(".") })

                Spacer()

                NumericButton(title: "0", action: { appendNumber("0") })

                Spacer()

                NumericButton(title: "<", action: removeLastCharacter)

                Spacer()
            }
        }
    }

    // MARK: - Functions

    private func appendNumber(_ number: String) {
        let newPrice = price + number

        if isValidUSD(newPrice) {
            price = newPrice
        }
    }

    private func removeLastCharacter() {
        if !price.isEmpty {
            price.removeLast()
        }
    }

    private func isValidUSD(_ price: String) -> Bool {
        guard !price.isEmpty else { return false }

        let regex = "^(?!0\\d)(\\d{1,3})(,\\d{3})*(\\.\\d{0,2})?$|^(1000)(\\.00)?$"
        let validPricePattern = NSPredicate(format: "SELF MATCHES %@", regex)

        guard validPricePattern.evaluate(with: price) else { return false }

        if let doubleValue = Double(price.replacingOccurrences(of: ",", with: "")) {
            return doubleValue <= 1000.0 && doubleValue >= 0.0
        }

        return false
    }


}

struct NumericButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Rubik-Medium", size: 24))
                .frame(width: 50, height: 50)
                .foregroundColor(Constants.Colors.black)
                .background(Constants.Colors.white)
                .cornerRadius(25)
        }
    }
}

#Preview(body: {
    PriceInputView(price: .constant(""), isPresented: .constant(true), titleText: "What price do you want to sell your product?")
})
