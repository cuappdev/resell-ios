//
//  ProductImageViewer.swift
//  Resell
//
//  Created by Andrew Gao on 9/3/26.
//

import Kingfisher
import SwiftUI

/// Full-screen, swipeable photo viewer for a listing, with pinch and
/// double-tap zoom on each photo.
struct ProductImageViewer: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss

    let images: [URL]
    @Binding var selectedIndex: Int

    /// The photo currently zoomed in, if any; paging is disabled while one is.
    @State private var zoomedIndex: Int?

    // MARK: - UI

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Constants.Colors.black
                    .ignoresSafeArea()

                TabView(selection: $selectedIndex) {
                    ForEach(images.indices, id: \.self) { index in
                        ZoomableProductImage(url: images[index]) { isZoomed in
                            if isZoomed {
                                zoomedIndex = index
                            } else if zoomedIndex == index {
                                zoomedIndex = nil
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .scrollDisabled(zoomedIndex != nil)
                .ignoresSafeArea()

                VStack {
                    HStack {
                        closeButton

                        Spacer()
                    }
                    .padding(.top, geometry.safeAreaInsets.top + 12)
                    .padding(.horizontal, 16)

                    Spacer()

                    if images.count > 1 {
                        ImageCountBadge(currentIndex: selectedIndex, count: images.count)
                            .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden()
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Constants.Colors.white)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close image viewer")
    }
}

/// One photo in the viewer. Reports through `onZoomChange` whenever it zooms in
/// or back out, so the pager can stop swiping while the photo is being panned.
private struct ZoomableProductImage: View {

    // MARK: - Properties

    let url: URL
    let onZoomChange: (Bool) -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // MARK: - UI

    var body: some View {
        GeometryReader { geometry in
            KFImage(url)
                .cacheOriginalImage()
                .placeholder {
                    ProgressView()
                        .tint(Constants.Colors.white)
                }
                .fade(duration: 0.2)
                .resizable()
                .scaledToFit()
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .scaleEffect(scale)
                .offset(offset)
                .contentShape(Rectangle())
                .gesture(magnificationGesture(in: geometry.size))
                .simultaneousGesture(dragGesture(in: geometry.size))
                .onTapGesture(count: 2, perform: toggleDoubleTapZoom)
        }
        .onDisappear {
            resetZoom()
        }
    }

    // MARK: - Private Methods

    private func toggleDoubleTapZoom() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if scale > 1 {
                resetZoom()
            } else {
                scale = 2.5
                lastScale = scale
                onZoomChange(true)
            }
        }
    }

    private func magnificationGesture(in size: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, 1), 5)
                offset = clamped(offset, scale: scale, in: size)
                onZoomChange(scale > 1.01)
            }
            .onEnded { _ in
                if scale <= 1.01 {
                    resetZoom()
                } else {
                    lastScale = scale
                    offset = clamped(offset, scale: scale, in: size)
                    lastOffset = offset
                    onZoomChange(true)
                }
            }
    }

    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                let proposedOffset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                offset = clamped(proposedOffset, scale: scale, in: size)
            }
            .onEnded { _ in
                guard scale > 1 else { return }
                lastOffset = offset
            }
    }

    private func clamped(
        _ proposedOffset: CGSize,
        scale: CGFloat,
        in size: CGSize
    ) -> CGSize {
        let maxX = size.width * (scale - 1) / 2
        let maxY = size.height * (scale - 1) / 2

        return CGSize(
            width: min(max(proposedOffset.width, -maxX), maxX),
            height: min(max(proposedOffset.height, -maxY), maxY)
        )
    }

    private func resetZoom() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
        onZoomChange(false)
    }
}
