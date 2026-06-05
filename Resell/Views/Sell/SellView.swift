//
//  SellView.swift
//  Resell
//

import SwiftUI

struct SellView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router

    // MARK: - UI

    var body: some View {
        VStack(spacing: 0) {
            header

            Spacer()

            actionButtons

            Spacer()
        }
        .background(Constants.Colors.white)
        .navigationBarBackButtonHidden()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sell")
                .font(Constants.Fonts.h1)
                .foregroundStyle(Constants.Colors.black)

            Text("Create a listing or submit a request")
                .font(Constants.Fonts.body2)
                .foregroundStyle(Constants.Colors.secondaryGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .padding(.top, 20)
        .padding(.bottom, 32)
    }

    private var actionButtons: some View {
        VStack(spacing: 16) {
            actionCard(
                title: "New Listing",
                subtitle: "List something you want to sell",
                image: "newListing",
                isPrimary: true
            ) {
                router.push(.newListingImages)
            }

            actionCard(
                title: "New Request",
                subtitle: "Post something you're looking for",
                image: "newRequest",
                isPrimary: false
            ) {
                router.push(.newRequest)
            }
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
    }

    private func actionCard(
        title: String,
        subtitle: String,
        image: String,
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isPrimary ? AnyShapeStyle(Constants.Colors.resellGradient) : AnyShapeStyle(Constants.Colors.purpleWash))
                        .frame(width: 52, height: 52)

                    Image(image)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(isPrimary ? .white : Constants.Colors.resellPurple)
                        .frame(width: 24, height: 24)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Constants.Fonts.title1)
                        .foregroundStyle(Constants.Colors.black)

                    Text(subtitle)
                        .font(Constants.Fonts.subtitle1)
                        .foregroundStyle(Constants.Colors.secondaryGray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Constants.Colors.inactiveGray)
            }
            .padding(20)
            .background(Constants.Colors.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isPrimary ? AnyShapeStyle(Constants.Colors.resellGradient) : AnyShapeStyle(Constants.Colors.stroke),
                        lineWidth: isPrimary ? 2 : 1
                    )
            }
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
