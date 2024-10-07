//
//  PopupModel.swift
//  Resell
//
//  Created by Richie Sun on 10/7/24.
//

import SwiftUI

struct PopupModal<T: View>: ViewModifier {
    let popupModal: T
    @Binding var isPresented: Bool

    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> T) {
        self._isPresented = isPresented
        self.popupModal = content()
    }

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
