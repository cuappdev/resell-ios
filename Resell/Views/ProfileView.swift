//
//  ProfileView.swift
//  Resell
//
//  Created by Richie Sun on 9/12/24.
//

import SwiftUI

struct ProfileView: View {

    // MARK: - Properties

    @StateObject private var viewModel = ProfileViewModel()

    // MARK: - UI

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                profileImageView
                    .padding(.bottom, 12)

                Text(viewModel.user?.username ?? "")
                    .font(Constants.Fonts.h3)
                    .foregroundStyle(Constants.Colors.black)
                    .padding(.bottom, 4)

                Text(viewModel.user?.name ?? "")
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .padding(.bottom, 16)

                Text(viewModel.user?.bio ?? "")
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.black)
                    .padding(.bottom, 28)

                profileTabsView
                    .padding(.bottom, 24)

                ProductsGalleryView(items: Constants.dummyItemsData)
            }
        }
    }

    private var profileImageView: some View {
        Image(viewModel.user?.profile ?? "justin")
            .resizable()
            .frame(width: 90, height: 90)
            .clipShape(.circle)
    }

    private var profileTabsView: some View {
        HStack(spacing: 0) {
            VStack {
                Image("listing")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Constants.Colors.black)

                Rectangle()
                    .foregroundStyle(Constants.Colors.black)
                    .frame(width: UIScreen.width / 3, height: 1)
            }

            VStack {
                Image("archive")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Constants.Colors.inactiveGray)

                Rectangle()
                    .foregroundStyle(Constants.Colors.inactiveGray)
                    .frame(width: UIScreen.width / 3, height: 1)
            }
            
            VStack {
                Image("wishlist")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Constants.Colors.inactiveGray)

                Rectangle()
                    .foregroundStyle(Constants.Colors.inactiveGray)
                    .frame(width: UIScreen.width / 3, height: 1)
            }


        }
    }

}

#Preview {
    ProfileView()
}
