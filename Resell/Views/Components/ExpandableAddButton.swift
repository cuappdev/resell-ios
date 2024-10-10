//
//  ExpandableAddButton.swift
//  Resell
//
//  Created by Richie Sun on 10/9/24.
//

import SwiftUI

/// Expandable button that animates to show options to add listing or add new request
struct ExpandableAddButton: View {

    // MARK: - Properties

    @State private var isExpanded: Bool = false

    // MARK: - UI

    var body: some View {
        VStack(alignment: .trailing, spacing: 24) {
            buttonOptions

            HStack {
                Spacer()

                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image("addNewListing")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipShape(.circle)
                        .background(.red)

                }
                .rotationEffect(.degrees(isExpanded ? -45 : 0))
                .buttonStyle(PlainButtonStyle())
                .clipShape(.circle)

            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var buttonOptions: some View {
        ZStack(alignment: .trailing) {
            NavigationLink {
                NewListingView()
            } label: {
                buttonContent(name: "New Listing", image: "newListing")
            }
            .animation(.easeInOut, value: isExpanded)
            .offset(y: isExpanded ? -64 : 64)
            .opacity(isExpanded ? 1 : 0)

            NavigationLink {
                NewRequestView()
            } label: {
                buttonContent(name: "New Request", image: "newRequest")
            }
            .animation(.easeInOut, value: isExpanded)
            .offset(y: isExpanded ? 0 : 64)
            .opacity(isExpanded ? 1 : 0)
        }
    }

    private func buttonContent(name: String, image: String) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(image)
                .resizable()
                .frame(width: 20, height: 20)

            Text(name)
                .font(Constants.Fonts.title2)
                .foregroundStyle(Constants.Colors.resellGradient)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Constants.Colors.white)
        .clipShape(.capsule)
        .overlay {
            RoundedRectangle(cornerRadius: 25)
                .stroke(Constants.Colors.resellGradient, lineWidth: 3)
        }
    }
}

#Preview {
    ExpandableAddButton()
}
