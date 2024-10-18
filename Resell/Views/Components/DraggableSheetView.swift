//
//  DraggableSheetView.swift
//  Resell
//
//  Created by Richie Sun on 10/18/24.
//

import SwiftUI

struct DraggableSheetView<Content: View>: View {
    // MARK: - Properties

    @State private var dragOffset: CGFloat = 0.0
    @State private var lastDragOffset: CGFloat = 0.0
    @State private var isDragging: Bool = false

    var maxDrag: CGFloat

    let content: () -> Content

    // MARK: - UI

    var body: some View {
        VStack {
            content()
                .offset(y: dragOffset + lastDragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.height
                            isDragging = true
                        }
                        .onEnded { value in
                            // Update the last drag offset based on the drag position
                            lastDragOffset += dragOffset + value.predictedEndTranslation.height * 0.3 // Adjust momentum effect

                            // Limit dragging downwards
                            if lastDragOffset > 0 {
                                lastDragOffset = 50
                            }

                            // Prevent dragging above the top
                            else if lastDragOffset < -maxDrag {
                                lastDragOffset = -200
                            }

                            // Reset drag offset
                            dragOffset = 0
                            isDragging = false
                        }
                )
                .animation(.easeOut, value: lastDragOffset) // Smooth transition
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea()
    }
}
