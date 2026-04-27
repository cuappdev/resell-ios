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
        Button {
            if let action {
                action()
            } else {
                router.pop()
            }
        } label: {
            chevronWithGlass
        }
        .buttonStyle(.plain)
    }

    /// On iOS 26 we apply our own circular Liquid Glass to the chevron and use a `.plain` button
    /// style above so the system's automatic toolbar capsule bubble does NOT also wrap us
    /// (which is what was producing the rectangular pill shape). On older OSes we just show
    /// the chevron at the standard hit-target size.
    @ViewBuilder
    private var chevronWithGlass: some View {
        let sized = label
            .frame(width: hitTargetSize.width, height: hitTargetSize.height)
            .contentShape(Circle())

        if #available(iOS 26.0, *) {
            sized.glassEffect(.regular.interactive(), in: Circle())
        } else {
            sized
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
