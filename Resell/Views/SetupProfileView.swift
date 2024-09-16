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

    @State private var didShowWebView: Bool = false
    @StateObject private var viewModel = SetupProfileViewModel()

    // MARK: - UI

    var body: some View {
        VStack {
            Text("Setup your profile")
                .font(Constants.Fonts.h3)
                .padding(.bottom, 40)

            profileImageView
                .padding(.bottom, 40)

            LabeledTextField(label: "Username")
                .padding(.bottom, 32)

            LabeledTextField(frameHeight: 83, label: "Bio",isMultiLine: true, maxCharacters: 255)
                .padding(.bottom, 24)

            eulaView

            Spacer()
        }
        .padding(.horizontal, 24)
        .sheet(isPresented: $didShowWebView) {
            WebView(url: URL(string: "https://www.cornellappdev.com/license/resell")!)
                .edgesIgnoringSafeArea(.all)
        }

    }

    private var profileImageView: some View {
        ZStack(alignment: .bottomTrailing) {
            viewModel.image
                .resizable()
                .frame(width: 132, height: 132)
                .background(Constants.Colors.stroke)
                .clipShape(.circle)
            PhotosPicker(selection: $viewModel.imageSelection, matching: .images, photoLibrary: .shared()) {
                Image("pencil.circle")
                    .shadow(radius: 2)
            }
            .buttonStyle(.borderless)
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
                .padding(.leading, 16)

            Button { didShowWebView = true } label: {
                Text(UIScreen.width < 380 ? " EULA" : " End User License Agreement")
                    .font(Constants.Fonts.title4)
                    .foregroundStyle(Constants.Colors.resellPurple)
                    .underline()
            }
        }
    }
}


#Preview {
    SetupProfileView()
}
