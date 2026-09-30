//
//  ExpandableAddButton.swift
//  Resell
//
//  Created by Richie Sun on 10/9/24.
//

import SwiftUI

/// Expandable Liquid Glass button that morphs to show options to add listing or add new request
struct ExpandableAddButton: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    @State private var isExpanded: Bool = false
    @Namespace private var glassNamespace

    // MARK: - UI

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if isExpanded {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isExpanded.toggle()
                    }
                }
            }

            GlassEffectContainer(spacing: 12) {
                VStack(alignment: .trailing, spacing: 24) {
                    if isExpanded {
                        buttonOptions
                    }

                    HStack {
                        Spacer()

                        Button {
                            withAnimation {
                                isExpanded.toggle()
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(Constants.Colors.white)
                                .frame(width: 64, height: 64)
                        }
                        .rotationEffect(.degrees(isExpanded ? -45 : 0))
                        .glassEffect(.regular.tint(Constants.Colors.resellPurple).interactive(), in: .circle)
                        .glassEffectID("addButton", in: glassNamespace)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                }
            }
            .padding(.trailing, Constants.Spacing.horizontalPadding)
            .padding(.bottom, Constants.Spacing.horizontalPadding)
        }
        .animation(.easeInOut, value: isExpanded)
    }

    private var buttonOptions: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Button {
                router.push(.newListingImages)
                withAnimation {
                    isExpanded = false
                }
            } label: {
                buttonContent(name: "New Listing", image: "newListing")
            }
            .glassEffect(.regular.interactive(), in: .capsule)
            .glassEffectID("newListing", in: glassNamespace)

            Button {
                router.push(.newRequest)
                withAnimation {
                    isExpanded = false
                }
            } label: {
                buttonContent(name: "New Request", image: "newRequest")
            }
            .glassEffect(.regular.interactive(), in: .capsule)
            .glassEffectID("newRequest", in: glassNamespace)
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
    }
}
