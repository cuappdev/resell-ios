//
//  NewListingDetailsView.swift
//  Resell
//
//  Created by Richie Sun on 10/14/24.
//

import SwiftUI

struct NewListingDetailsView: View {

    // MARK: - Properties

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: NewListingViewModel
    @EnvironmentObject var mainViewModel: MainViewModel

    @State private var priceFieldPosition: CGFloat = 0.0

    // MARK: - UI

    var body: some View {
        VStack(spacing: 32) {
            LabeledTextField(label: "Title", text: $viewModel.titleText)
                .padding(.top, 32)

            priceTextField
                .background {
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: PriceFieldPositionKey.self, value: geometry.frame(in: .global).maxY)
                    }
                }
                .onPreferenceChange(PriceFieldPositionKey.self) { value in
                    self.priceFieldPosition = value
                }

            LabeledTextField(label: "Item Description", maxCharacters: 1000, frameHeight: 120, isMultiLine: true, placeholder: "Enter item details... \nCondition \nDimensions", text: $viewModel.descriptionText)

            filtersView

            Spacer()

            PurpleButton(isActive: viewModel.checkInputIsValid(), text: "Continue") {
                viewModel.createNewListing()
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
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    withAnimation {
                        viewModel.isDetailsView = false
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .tint(Constants.Colors.black)
                }
            }

            ToolbarItem(placement: .principal) {
                Text("New Listing")
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
        .sheet(isPresented: $viewModel.didShowPriceInput) {
            PriceInputView(price: $viewModel.priceText, isPresented: $viewModel.didShowPriceInput, titleText: "What price do you want to sell your product?")
                .presentationDetents([.height(UIScreen.height - priceFieldPosition - (UIScreen.height < 700 ? 0 : 50))])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(25)
        }
    }

    private var priceTextField: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Price")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.black)

                Text("$\(viewModel.priceText)")
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.black)
                    .frame(width: 80, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Constants.Colors.wash)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onTapGesture {
                        viewModel.didShowPriceInput = true
                    }
            }

            Spacer()
        }
    }

    private var filtersView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Categories")
                .font(Constants.Fonts.title1)
                .foregroundStyle(Constants.Colors.black)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Constants.filters, id: \.id) { filter in
                        if filter.title != "Recent" {
                            FilterButton(filter: filter, isSelected: viewModel.selectedFilter == filter.title) {
                                viewModel.selectedFilter = filter.title
                            }
                        }
                    }
                }
                .padding(.vertical, 1)
                .padding(.horizontal, 1)
            }
        }
    }
}

// MARK: - PreferenceKey for PriceField Position

struct PriceFieldPositionKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: CGFloat = 0.0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    NewListingDetailsView()
}
