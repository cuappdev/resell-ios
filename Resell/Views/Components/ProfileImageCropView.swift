//
//  ProfileImageCropView.swift
//  Resell
//
//  Created by Andrew Gao on 9/30/26.
//

import SwiftUI

/// Full-screen circular cropper for a new profile photo: pinch or use the slider
/// to zoom, drag to reposition, then "Use Photo" hands back the square crop.
struct ProfileImageCropView: View {

    // MARK: - Properties

    let image: UIImage
    let onCancel: () -> Void
    let onSave: (UIImage) -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // MARK: - UI

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let availableWidth = max(proxy.size.width - 32, 1)
                let availableHeight = max(proxy.size.height * 0.58, 1)
                let cropSize = max(min(availableWidth, availableHeight), 1)

                VStack(spacing: 28) {
                    Spacer()

                    cropPreview(size: cropSize)

                    zoomControls(cropSize: cropSize)
                        .padding(.horizontal, 32)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Constants.Colors.white)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel", action: onCancel)
                    }

                    ToolbarItem(placement: .principal) {
                        Text("Adjust Photo")
                            .font(Constants.Fonts.title1)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Use Photo") {
                            onSave(croppedImage(cropSize: cropSize))
                        }
                        .font(Constants.Fonts.title2)
                    }
                }
            }
        }
    }

    private func zoomControls(cropSize: CGFloat) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "minus.magnifyingglass")
                Slider(
                    value: Binding(
                        get: { scale },
                        set: { newScale in
                            scale = newScale
                            offset = clampedOffset(
                                offset,
                                cropSize: cropSize,
                                scale: newScale
                            )
                        }
                    ),
                    in: 1...4,
                    onEditingChanged: { isEditing in
                        if !isEditing {
                            lastScale = scale
                            lastOffset = offset
                        }
                    }
                )
                Image(systemName: "plus.magnifyingglass")
            }
            .foregroundStyle(Constants.Colors.black)

            Text("Pinch to zoom and drag to reposition")
                .font(Constants.Fonts.subtitle1)
                .foregroundStyle(Constants.Colors.secondaryGray)
        }
    }

    private func cropPreview(size: CGFloat) -> some View {
        let imageWidth = max(image.size.width, 1)
        let imageHeight = max(image.size.height, 1)
        let baseScale = max(size / imageWidth, size / imageHeight)

        return Image(uiImage: image)
            .resizable()
            .frame(
                width: imageWidth * baseScale,
                height: imageHeight * baseScale
            )
            .scaleEffect(scale)
            .offset(offset)
            .frame(width: size, height: size)
            .background(Constants.Colors.black)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(Constants.Colors.white, lineWidth: 2)
            }
            .contentShape(Circle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = clampedOffset(
                            CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            ),
                            cropSize: size,
                            scale: scale
                        )
                    }
                    .onEnded { _ in
                        lastOffset = offset
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = min(max(lastScale * value, 1), 4)
                        offset = clampedOffset(offset, cropSize: size, scale: scale)
                    }
                    .onEnded { _ in
                        lastScale = scale
                        lastOffset = offset
                    }
            )
    }

    // MARK: - Private Methods

    private func clampedOffset(
        _ proposedOffset: CGSize,
        cropSize: CGFloat,
        scale: CGFloat
    ) -> CGSize {
        let imageWidth = max(image.size.width, 1)
        let imageHeight = max(image.size.height, 1)
        let baseScale = max(cropSize / imageWidth, cropSize / imageHeight)
        let displayedWidth = imageWidth * baseScale * scale
        let displayedHeight = imageHeight * baseScale * scale
        let maximumX = max(0, (displayedWidth - cropSize) / 2)
        let maximumY = max(0, (displayedHeight - cropSize) / 2)

        return CGSize(
            width: min(max(proposedOffset.width, -maximumX), maximumX),
            height: min(max(proposedOffset.height, -maximumY), maximumY)
        )
    }

    private func croppedImage(cropSize: CGFloat) -> UIImage {
        let normalizedImage = image.flattenedOrientation()
        let imageSize = normalizedImage.size
        let baseScale = max(cropSize / imageSize.width, cropSize / imageSize.height)
        let displayScale = baseScale * scale
        let cropSide = cropSize / displayScale

        let cropRect = CGRect(
            x: min(
                max((imageSize.width - cropSide) / 2 - offset.width / displayScale, 0),
                imageSize.width - cropSide
            ),
            y: min(
                max((imageSize.height - cropSide) / 2 - offset.height / displayScale, 0),
                imageSize.height - cropSide
            ),
            width: cropSide,
            height: cropSide
        )

        guard let source = normalizedImage.cgImage else { return normalizedImage }
        let pixelScale = CGFloat(source.width) / imageSize.width
        let pixelRect = CGRect(
            x: cropRect.minX * pixelScale,
            y: cropRect.minY * pixelScale,
            width: cropRect.width * pixelScale,
            height: cropRect.height * pixelScale
        ).integral

        guard let cropped = source.cropping(to: pixelRect) else { return normalizedImage }
        return UIImage(cgImage: cropped, scale: normalizedImage.scale, orientation: .up)
    }
}
