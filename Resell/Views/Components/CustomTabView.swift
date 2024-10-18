//
//  CustomTabView.swift
//  Resell
//
//  Created by Richie Sun on 10/9/24.
//

import SwiftUI

struct CustomTabView: View {

    // MARK: - Properties

    @Binding var isHidden: Bool
    @Binding var selection: Int

    // MARK: - UI

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack() {
                if selection == 0 {
                    HomeView()
                } else if selection == 1 {
                    SavedView()
                } else if selection == 2 {
                    ChatsView()
                } else if selection == 3 {
                    ProfileView()
                }
            }

            if !isHidden {
                HStack {
                    ForEach(0..<4, id: \.self) { index in
                        TabViewIcon(selectionIndex: $selection, itemIndex: index)
                            .frame(width: 28, height: 28)

                        if index != 3 {
                            Spacer()
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .padding(.horizontal, 40)
                .padding(.top, 16)
                .padding(.bottom, 36)
                .background(Constants.Colors.white)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(radius: 4)
                .offset(y: 34)
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: isHidden)
            }
        }
    }
}
