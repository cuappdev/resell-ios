//
//  SwipableRow.swift
//  Resell
//
//  Created by Richie Sun on 11/8/24.
//

import SwiftUI

/// A reusable view that provides swipe-to-delete functionality.
/// When swiped past halfway, the delete action is confirmed with haptic feedback, and the row slides out.
struct SwipeableRow<Content: View>: View {

    // MARK: - Properties

    /// Tracks if the halfway point has been reached to trigger haptic feedback only once.
    @State private var hasReachedHalfway = false

    /// Tracks if the row is marked as deleted to change the appearance.
    @State private var isDeleted: Bool = false

    /// The current horizontal offset for the swipe gesture.
    @State private var offset: CGFloat = 0

    /// Tracks if the row is currently being dragged.
    @GestureState private var isDragging = false

    /// The main content of the row.
    let content: Content

    /// The action to perform when the row is deleted.
    let onDelete: () -> Void

    // MARK: - Init

    init(@ViewBuilder content: () -> Content, onDelete: @escaping () -> Void) {
        self.content = content()
        self.onDelete = onDelete
    }

    // MARK: - UI

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack {
                Spacer()

                Button {
                    deleteRow()
                } label: {
                    Image("trash")
                        .foregroundStyle(Constants.Colors.white)
                        .frame(width: 78, height: 78)
                        .background(!isDeleted ? Constants.Colors.errorRed : nil)
                        .clipShape(.rect(cornerRadius: 15))
                }
            }
            .background(isDeleted ? Constants.Colors.errorRed : Constants.Colors.white)
            .clipShape(.rect(cornerRadius: 15))

            content
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .updating($isDragging) { value, state, _ in
                            state = true
                        }
                        .onChanged { gesture in
                            if gesture.translation.width < 0 {
                                offset = gesture.translation.width
                            } else if offset < 0 {
                                offset = gesture.translation.width
                            }

                            withAnimation(.easeInOut(duration: 0.15)) {
                                isDeleted = offset < -(UIScreen.width / 2)
                            }

                            if offset < -(UIScreen.width / 2) && !hasReachedHalfway {
                                HapticFeedbackGenerator.impact()
                                hasReachedHalfway = true
                            }
                        }
                        .onEnded { _ in
                            if offset < -(UIScreen.width / 2) {
                                deleteRow()
                            } else if offset < -78 {
                                offset = -90
                                hasReachedHalfway = false
                            } else {
                                offset = 0
                                hasReachedHalfway = false
                            }
                        }
                )
                .animation(.easeInOut, value: offset)
        }
        .contentShape(Rectangle())
    }

    // MARK: - Functions

    private func deleteRow() {
        withAnimation {
            isDeleted = true
            onDelete()
            offset = -UIScreen.width
        }
    }
}
