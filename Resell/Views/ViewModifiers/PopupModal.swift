//
//  PopupModel.swift
//  Resell
//
//  Created by Richie Sun on 10/7/24.
//

import SwiftUI

/// A view modifier that displays a modal popup overlay on top of the modified view when `isPresented` is true.
struct PopupModal<T: View>: ViewModifier {

    // MARK: - Properties

    /// The content view for the popup modal.
    let popupModal: T

    /// A binding to determine whether the modal is presented.
    @Binding var isPresented: Bool

    // MARK: - Init

    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> T) {
        self._isPresented = isPresented
        self.popupModal = content()
    }

    // MARK: - ViewModifier

    func body(content: Content) -> some View {
        content
            .overlay(modalContent())
    }

    @ViewBuilder private func modalContent() -> some View {
        GeometryReader { geometry in
            if isPresented {
                Constants.Colors.black.opacity(0.15)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation { isPresented = false }
                    }

                ZStack(alignment: .topTrailing) {
                    popupModal

                    Button {
                        withAnimation { isPresented = false }
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .tint(Constants.Colors.secondaryGray)
                            .padding(.top, 24)
                            .padding(.trailing, 24)
                    }
                }
                .background(Constants.Colors.white)
                .clipShape(.rect(cornerRadius: 20))
                .shadow(radius: 20)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                .scaleEffect(isPresented ? 1 : 0.8)
                .opacity(isPresented ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: isPresented)
                .transition(.scale)
            }
        }
    }
}

// MARK: - View Extension

extension View {
    
    /// Presents a popup modal at the center of the screen, over the view its applied to
    ///
    /// This view modifier can be applied to any SwiftUI view. When the user adds this modifier
    /// a popup modal view will be presented over the view when isPresented is true
    ///
    /// - Returns: A modified view with popup modal functionality.
    func popupModal<T: View>(isPresented: Binding<Bool>, @ViewBuilder content: () -> T) -> some View {
        self.modifier(PopupModal(isPresented: isPresented, content: content))
    }
}
