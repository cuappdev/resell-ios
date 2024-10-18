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

    @State var showMenu: Bool = false

    var options: [Option]

    // MARK: - UI

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if showMenu {
                Color.black
                    .opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showMenu = false
                        }
                    }
            }

            VStack(alignment: .trailing, spacing: 30) {
                Image(systemName: "ellipsis")
                    .resizable()
                    .frame(width: 24, height: 6)
                    .foregroundStyle(Constants.Colors.white)
                    .onTapGesture {
                        withAnimation {
                            showMenu = true
                        }
                    }
                if showMenu {
                    VStack {
                        ForEach(options.indices, id: \.self) { index in
                            HStack(alignment: .center) {
                                Text(options[index].name)
                                    .font(Constants.Fonts.body1)
                                    .foregroundStyle(options[index].isRed ? Constants.Colors.errorRed : Constants.Colors.black)

                                Spacer()

                                Image(options[index].icon)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundStyle(options[index].isRed ? Constants.Colors.errorRed : Constants.Colors.black)
                            }
                            .padding(.vertical, 11)
                            .padding(.horizontal, 16)

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
                }
            }
            .padding(.trailing, Constants.Spacing.horizontalPadding)
        }
    }
}

struct Option {
    let name: String
    let icon: String
    var isRed: Bool = true
    let action: () -> Void
}

#Preview {
    OptionsMenuView(options: [
        Option(name: "Share", icon: "share", action: {
            print("COOL")
        }),
        Option(name: "Report", icon: "flag", action: {
            print("COOL")
        })
    ])
}
