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
                .padding(.top, 20)

            Spacer()
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
        .padding(.top, 40)
        .photosPicker(isPresented: $viewModel.photosPickerPresented, selection: $viewModel.selectedItem, matching: .images, photoLibrary: .shared())
        .onChange(of: viewModel.selectedItem) { newItem in
            Task {
                await viewModel.updateFeedbackItems(newItem: newItem)
            }
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
                        .clipped()
                        .cornerRadius(10)

                    Button(action: {
                        viewModel.selectedImages.remove(at: index)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.red)
                            .padding(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            if viewModel.selectedImages.count < 3 {
                Button(action: {
                    viewModel.photosPickerPresented = true
                }) {
                    VStack {
                        Image(systemName: "plus")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                        Text("Add Image")
                            .font(.caption)
                    }
                    .frame(width: imageSize, height: imageSize)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
            }
        }
    }
    
}

#Preview {
    SendFeedbackView()
}
