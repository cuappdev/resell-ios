//
//  EditProfileView.swift
//  Resell
//
//  Created by Richie Sun on 11/8/24.
//

import SwiftUI

struct EditProfileView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    @StateObject private var viewModel = EditProfileViewModel()

    // MARK: - UI

    var body: some View {
        VStack {
            profileImageView
                .padding(.bottom, 40)

            nameView

            editFieldsView

            Spacer()
        }
        .padding(.top, 40)
        .background(Constants.Colors.white)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Edit Profile")
                    .font(Constants.Fonts.h3)
                    .foregroundStyle(Constants.Colors.black)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.updateProfile()
                } label: {
                    Text("Save")
                        .font(Constants.Fonts.title1)
                        .foregroundStyle(Constants.Colors.resellPurple)
                }
            }
        }
        .loadingView(isLoading: viewModel.isLoading)
        .onAppear {
            viewModel.getUser()
        }
        .onChange(of: viewModel.isLoading) { newValue in
            if !newValue {
                router.popToRoot()
            }
        }
        .endEditingOnTap()
    }

    private var profileImageView: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: viewModel.selectedImage)
                .resizable()
                .frame(width: 132, height: 132)
                .background(Constants.Colors.stroke)
                .clipShape(.circle)

            Button {
                viewModel.didShowPhotosPicker = true
            } label: {
                Image("pencil.circle")
                    .shadow(radius: 2)
            }
            .buttonStyle(.borderless)
        }
        .photosPicker(isPresented: $viewModel.didShowPhotosPicker, selection: $viewModel.selectedItem, matching: .images, photoLibrary: .shared())
        .onChange(of: viewModel.selectedItem) { newItem in
            Task {
                await viewModel.updateUserProfile(newItem: newItem)
            }
        }
    }

    private var nameView: some View {
        VStack(spacing: 40) {
            HStack {
                Text("Name")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.black)

                Spacer()

                Text("\(viewModel.user?.givenName ?? "") \(viewModel.user?.familyName ?? "")")
                    .font(Constants.Fonts.body1)
                    .foregroundStyle(Constants.Colors.black)
            }

            HStack {
                Text("NetID")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.black)

                Spacer()

                Text(viewModel.user?.netid ?? "")
                    .font(Constants.Fonts.body1)
                    .foregroundStyle(Constants.Colors.black)
            }
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
    }

    private var editFieldsView: some View {
        VStack(spacing: 40) {
            HStack(spacing: 60) {
                Text("Username")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.black)

                TextField("", text: $viewModel.username)
                    .font(Constants.Fonts.body1)
                    .foregroundStyle(Constants.Colors.black)
                    .multilineTextAlignment(.trailing)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(Constants.Colors.wash)
                    .clipShape(.rect(cornerRadius: 10))
            }

            HStack(spacing: 60) {
                Text("Venmo Link")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.black)

                TextField("", text: $viewModel.venmoLink)
                    .font(Constants.Fonts.body1)
                    .foregroundStyle(Constants.Colors.black)
                    .multilineTextAlignment(.trailing)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(Constants.Colors.wash)
                    .clipShape(.rect(cornerRadius: 10))
            }

            HStack(alignment: .top, spacing: 60) {
                Text("Bio")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.black)

                TextEditor(text: $viewModel.bio)
                    .font(Constants.Fonts.body1)
                    .foregroundColor(Constants.Colors.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .scrollContentBackground(.hidden)
                    .background(Constants.Colors.wash)
                    .cornerRadius(10)
                    .frame(height: 100)
                    .onChange(of: viewModel.bio) { newText in
                        if newText.count > 1000 {
                            viewModel.bio = String(newText.prefix(1000))
                        }
                    }
            }
        }
        .padding(.top, 40)
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
    }
}

#Preview {
    EditProfileView()
}
