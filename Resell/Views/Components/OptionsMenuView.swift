//
//  OptionsMenuView.swift
//  Resell
//
//  Created by Richie Sun on 10/16/24.
//

import SwiftUI

/// Reusable Popup options menu that performs an action on tap
struct OptionsMenuView: View {

    // MARK: - Properties

    @Binding var showMenu: Bool

    var options: [Option]

    // MARK: - UI

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        showMenu = false
                    }
                }

            VStack(spacing: 0) {
                ForEach(options.indices, id: \.self) { index in

                    switch options[index] {
                    case .share(let url, let item):
                        ShareLink(item: url, subject: Text("Check out this \(item) on Resell")) {
                            optionView(name: "Share", icon: "share")
                        }
                    case .report(let destination):
                        NavigationLink {
                            destination
                        } label: {
                            optionView(name: "Report", icon: "flag")
                        }
                    case .delete:
                        optionView(name: "Delete", icon: "trash", isRed: true)
                    case .block:
                        optionView(name: "Block", icon: "block")
                    case .unblock:
                        optionView(name: "Unblock", icon: "block")
                    }


                    if index != options.count - 1 {
                        Divider()
                            .frame(height: 0.5)
                            .background(Constants.Colors.black.opacity(0.36))
                    }

                }
            }
            .frame(width: 250)
            .background(Constants.Colors.wash.opacity(0.8))
            .clipShape(.rect(cornerRadius: 12))
            .padding(.trailing, Constants.Spacing.horizontalPadding)
            .scaleEffect(showMenu ? 1 : 0, anchor: .topTrailing)
            .animation(.spring, value: showMenu)
            .transition(.scale(scale: 0, anchor: .topTrailing))
        }
    }

    private func optionView(name: String, icon: String, isRed: Bool = false) -> some View {
        HStack(alignment: .center) {
            Text(name)
                .font(.system(size: 17))
                .foregroundStyle(isRed ? Constants.Colors.errorRed : Constants.Colors.black)

            Spacer()

            Image(icon)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundStyle(isRed ? Constants.Colors.errorRed : Constants.Colors.black)
        }
        .frame(height: 44)
        .padding(.horizontal, 16)

    }
}

enum Option {
    case share(url: URL, itemName: String)
    case report(destination: AnyView)
    case block
    case unblock
    case delete
}
