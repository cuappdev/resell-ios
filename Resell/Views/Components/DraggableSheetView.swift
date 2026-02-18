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
    @State private var lastDragOffset: CGFloat = -50
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
                            let potentialOffset = lastDragOffset + value.translation.height
                            
                            // Prevent dragging above the initial position (-50)
                            if potentialOffset < -50 {
                                // Add resistance when trying to drag up past the start
                                dragOffset = (-50 - lastDragOffset) + (value.translation.height - (-50 - lastDragOffset)) * 0.1
                            } else {
                                dragOffset = value.translation.height
                            }
                            
                            isDragging = true
                        }
                        .onEnded { value in
                            // Update the last drag offset based on the drag position
                            lastDragOffset += dragOffset + value.predictedEndTranslation.height * 0.3 // Adjust momentum effect

                            // Limit dragging downwards (can pull down a bit)
                            if lastDragOffset > 0 {
                                lastDragOffset = 50
                            }
                            
                            // Prevent dragging above the initial position
                            else if lastDragOffset < -50 {
                                lastDragOffset = -50
                            }

                            // Prevent dragging above the max drag limit
                            if lastDragOffset < -maxDrag {
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
