////
////  DraggableSheetView.swift
////  Resell
////
////  Created by Richie Sun on 10/18/24.
////
//
import SwiftUI

struct DraggableSheetView<Content: View>: View {
    @State private var dragOffset: CGFloat = 0.0
    @State private var lastDragOffset: CGFloat = 0.0
    
    var startY: CGFloat
    
    let content: () -> Content

    var body: some View {
        GeometryReader { geo in
            let screenHeight = geo.size.height
            let halfScreen = screenHeight / 2
            
            let travelDistance = startY - (halfScreen - 10)

            VStack(spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(40)
            .offset(y: startY + dragOffset + lastDragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = value.translation.height
                        let potential = lastDragOffset + translation
                        
                        if potential < -travelDistance {
                            dragOffset = (-travelDistance - lastDragOffset) + (translation - (-travelDistance - lastDragOffset)) * 0.2
                        }
                        else if potential > 0 {
                            dragOffset = (0 - lastDragOffset) + (translation - (0 - lastDragOffset)) * 0.2
                        }
                        else {
                            dragOffset = translation
                        }
                    }
                    .onEnded { value in
                        let velocity = value.predictedEndTranslation.height
                        let finalPos = lastDragOffset + dragOffset + (velocity * 0.5)

                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            // If user flicked or dragged more than 30% of the way up
                            if finalPos < -travelDistance * 0.3 {
                                lastDragOffset = -travelDistance
                            } else {
                                lastDragOffset = 0
                            }
                            dragOffset = 0
                        }
                    }
            )
        }
        .ignoresSafeArea()
    }
}
