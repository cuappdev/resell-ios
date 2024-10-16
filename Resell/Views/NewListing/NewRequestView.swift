//
//  NewRequestView.swift
//  Resell
//
//  Created by Richie Sun on 10/9/24.
//

import SwiftUI

struct NewRequestView: View {

    // MARK: - Properties

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var mainViewModel: MainViewModel
    @StateObject private var viewModel = NewRequestViewModel()

    @State private var priceFieldPosition: CGFloat = 0.0

    // MARK: - UI

    var body: some View {
        VStack(spacing: 32) {
            LabeledTextField(label: "Title", text: $viewModel.titleText)
                .padding(.top, 32)

            minMaxTextFields
                .background {
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: PriceFieldPositionKey.self, value: geometry.frame(in: .global).maxY)
                    }
                }
                .onPreferenceChange(PriceFieldPositionKey.self) { value in
                    self.priceFieldPosition = value
                }

            LabeledTextField(label: "Item Description", maxCharacters: 1000, frameHeight: 250, isMultiLine: true, placeholder: "Enter item details... \nCondition \nDimensions", text: $viewModel.descriptionText)

            Spacer()

            PurpleButton(isActive: viewModel.checkInputIsValid(), text: "Continue") {
                viewModel.createNewRequest()
                dismiss()
                withAnimation {
                    mainViewModel.hidesTabBar = false
                }
            }
        }
        .padding(.horizontal, 24)
        .background(Constants.Colors.white)
        .endEditingOnTap()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Request Details")
                    .font(Constants.Fonts.h3)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                    withAnimation {
                        mainViewModel.hidesTabBar = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .tint(Constants.Colors.black)
                }
            }
        }
        .onAppear {
            withAnimation {
                mainViewModel.hidesTabBar = true
            }
        }
        .sheet(isPresented: $viewModel.didShowPriceInput) {
            PriceInputView(price: viewModel.isMinText ? $viewModel.priceTextMin : $viewModel.priceTextMax, isPresented: $viewModel.didShowPriceInput, titleText: "What is the \(viewModel.isMinText ? "minimum" : "maximum") of your preferred price range?")
                .presentationDetents([.height(UIScreen.height - priceFieldPosition - (UIScreen.height < 700 ? 0 : 50))])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(25)
        }
    }

    private var minMaxTextFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Price")
                .font(Constants.Fonts.title1)
                .foregroundStyle(Constants.Colors.black)

            HStack {
                Text("$\(viewModel.priceTextMin)")
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.black)
                    .frame(width: 100, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Constants.Colors.wash)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture {
                        viewModel.isMinText = true
                        viewModel.didShowPriceInput = true
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Text("min")
                            .font(Constants.Fonts.body2)
                            .foregroundStyle(Constants.Colors.secondaryGray)
                            .padding(8)
                    }

                Spacer()
                    .overlay {
                        Text("-")
                            .font(.custom("Rubik-Medium", size: 18))
                    }

                Text("$\(viewModel.priceTextMax)")
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.black)
                    .frame(width: 100, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Constants.Colors.wash)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture {
                        viewModel.isMinText = false
                        viewModel.didShowPriceInput = true
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Text("max")
                            .font(Constants.Fonts.body2)
                            .foregroundStyle(Constants.Colors.secondaryGray)
                            .padding(8)
                    }
            }
        }
    }
}

#Preview {
    NewRequestView()
}
