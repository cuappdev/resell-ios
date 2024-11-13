//
//  SendFeedbackView.swift
//  Resell
//
//  Created by Richie Sun on 10/5/24.
//

import SwiftUI
import PhotosUI

struct SendFeedbackView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    @StateObject private var viewModel = SendFeedbackViewModel()
    private let imageSize: CGFloat = (UIScreen.width - 72) / 3

    // MARK: - UI

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Thanks for using Resell! We appreciate any feedback to improve your experience.")
                .font(Constants.Fonts.body1)
                .foregroundStyle(Constants.Colors.black)
                .multilineTextAlignment(.center)

            LabeledTextField(label: "", maxCharacters: 1000, frameHeight: 190, isMultiLine: true, text: $viewModel.feedbackText)

            Text("Image Upload")
                .font(Constants.Fonts.title1)
                .padding(.top, 32)

            imageSelectionView
                .padding(.top, 12)

            Spacer()
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .padding(.top, 40)
        .background(Constants.Colors.white)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Send Feedback")
                    .font(Constants.Fonts.h3)
                    .foregroundStyle(Constants.Colors.black)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.submitFeedback()
                } label: {
                    Text("Submit")
                        .font(Constants.Fonts.title1)
                        .foregroundStyle(Constants.Colors.resellPurple)
                }
            }
        }
        .photosPicker(isPresented: $viewModel.didShowPhotosPicker, selection: $viewModel.selectedItem, matching: .images, photoLibrary: .shared())
        .onChange(of: viewModel.selectedItem) { newItem in
            Task {
                await viewModel.updateFeedbackItems(newItem: newItem)
            }
        }
        .popupModal(isPresented: $viewModel.didShowPopup) {
            popupModalContent
        }
    }

    private var imageSelectionView: some View {
        HStack(spacing: 12) {
            ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: viewModel.selectedImages[index])
                        .resizable()
                        .scaledToFill()
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(.rect(cornerRadius: 10))
                        .padding(.top, 8)

                    Button {
                        viewModel.selectedIndex = index
                        viewModel.togglePopup(isPresenting: true)
                    } label: {
                        Image("deleteImage")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.red)
                    }
                }
            }

            if viewModel.selectedImages.count < 3 {
                Button {
                    viewModel.didShowPhotosPicker = true
                } label: {
                    VStack {
                        Image("addImage")
                            .shadow(radius: 2)
                    }
                    .frame(width: imageSize, height: imageSize)
                    .background(Constants.Colors.wash)
                    .clipShape(.rect(cornerRadius: 10))
                    .padding(.top, 8)
                }
            }
        }
    }

    private var popupModalContent: some View {
        VStack(spacing: 24) {
            Text("Delete Image")
                .font(Constants.Fonts.h3)

            Text("Are you sure you’d like to delete this image?")
                .font(Constants.Fonts.body2)
                .multilineTextAlignment(.center)
                .frame(width: 200)

            PurpleButton(text: "Delete", horizontalPadding: 100) {
                viewModel.removeImage()
            }

            Button{
                viewModel.togglePopup(isPresenting: false)
            } label: {
                Text("Cancel")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.secondaryGray)
            }
        }
        .padding(Constants.Spacing.horizontalPadding)
    }

}

#Preview {
    SendFeedbackView()
}
