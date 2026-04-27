//
//  BackButton.swift
//  Resell
//
//  Created by Andrew Gao on 4/27/26.
//

import SwiftUI

/// Reusable back button that guarantees a 44x44 pt minimum hit target so taps
/// anywhere inside the iOS 26 Liquid Glass capsule reliably trigger the action.
struct BackButton: View {

    // MARK: - Style

    enum Style {
        /// Default: SF Symbol `chevron.left` at 17pt medium, black tint.
        case systemChevron
        /// Resizable SF Symbol `chevron.left` with an explicit content size.
        case systemChevronResizable(width: CGFloat, height: CGFloat)
        /// Asset image (e.g. `chevron.left`, `chevron.left.white`) with explicit size and tint.
        case assetChevron(name: String, size: CGSize, tint: Color = Constants.Colors.black)
    }

    // MARK: - Properties

    var style: Style = .systemChevron
    /// Size of the tappable rect surrounding the chevron. Defaults to 44x44 (Apple HIG minimum).
    /// Pass a smaller width when embedded in a custom HStack header that needs to preserve a narrower visual slot.
    var hitTargetSize: CGSize = CGSize(width: 44, height: 44)
    var action: (() -> Void)? = nil

    @EnvironmentObject private var router: Router

    // MARK: - UI

    var body: some View {
        let button = Button {
            if let action {
                action()
            } else {
                router.pop()
            }
        } label: {
            label
                .frame(width: hitTargetSize.width, height: hitTargetSize.height)
                .contentShape(Circle())
        }

        if #available(iOS 17.0, *) {
            button.buttonBorderShape(.circle)
        } else {
            button
        }
    }

    @ViewBuilder
    private var label: some View {
        switch style {
        case .systemChevron:
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Constants.Colors.black)
        case .systemChevronResizable(let width, let height):
            Image(systemName: "chevron.left")
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
                .foregroundStyle(Constants.Colors.black)
        case .assetChevron(let name, let size, let tint):
            Image(name)
                .resizable()
                .frame(width: size.width, height: size.height)
                .foregroundStyle(tint)
        }
    }
}
