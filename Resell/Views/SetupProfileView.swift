//
//  SetupProfileView.swift
//  Resell
//
//  Created by Richie Sun on 9/16/24.
//

import PhotosUI
import SwiftUI

struct SetupProfileView: View {

    // MARK: - Properties

    @StateObject private var viewModel = SetupProfileViewModel()
    @Binding var userDidLogin: Bool

    // MARK: - UI

    var body: some View {
        NavigationStack {
            VStack {
                profileImageView
                    .padding(.vertical, 40)

                LabeledTextField(label: "Username", text: $viewModel.username)
                    .padding(.bottom, 32)

                LabeledTextField(label: "Bio", maxCharacters: 255, frameHeight: 83, isMultiLine: true, text: $viewModel.bio)
                    .padding(.bottom, 24)

                eulaView

                Spacer()

                NavigationPurpleButton(isActive: viewModel.checkInputIsValid(), text: "Next", horizontalPadding: 80, destination: VenmoView(userDidLogin: $userDidLogin))
            }
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .background(Constants.Colors.white)
        .sheet(isPresented: $viewModel.didShowWebView) {
            WebView(url: URL(string: "https://www.cornellappdev.com/license/resell")!)
                .edgesIgnoringSafeArea(.all)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Setup your profile")
                    .font(Constants.Fonts.h3)
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

    private var eulaView: some View {
        HStack(spacing: 0) {
            Button(action: { viewModel.didAgreeWithEULA.toggle() }) {
                ZStack {
                    Circle()
                        .fill(Constants.Colors.wash)
                        .frame(width: 24, height: 24)
                        .overlay {
                            Circle()
                                .stroke(Constants.Colors.resellPurple, lineWidth: 2.5)
                                .frame(width: 24, height: 24)
                        }

                    if viewModel.didAgreeWithEULA {
                        Circle()
                            .fill(Constants.Colors.resellPurple)
                            .frame(width: 17, height: 17)
                    }
                }
            }

            Text("I agree to Resell’s")
                .font(Constants.Fonts.title4)
                .foregroundStyle(Constants.Colors.black)
                .padding(.leading, 16)

            Button { viewModel.didShowWebView = true } label: {
                Text(UIScreen.width < 380 ? " EULA" : " End User License Agreement")
                    .font(Constants.Fonts.title4)
                    .foregroundStyle(Constants.Colors.resellPurple)
                    .underline()
            }
        }
    }
}

#Preview {
    SetupProfileView(userDidLogin: .constant(true))
}
