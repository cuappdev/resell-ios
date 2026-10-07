//
//  GlassToolbarModifier.swift
//  Resell
//
//  Created by Andrew Gao on 9/3/26.
//

import SwiftUI

/// Liquid Glass background for the floating toolbar controls that sit over a
/// scrolling feed (search pill, filter button, notification button).
///
/// The near-clear fill and explicit `contentShape` are load-bearing: neither
/// `glassEffect` nor `Material` alone claims the whole pill for hit testing, so
/// taps near the edge of a control would fall through to the content behind it.
struct GlassToolbarModifier: ViewModifier {

    var cornerRadius: CGFloat = 999
    /// Opaque enough to keep foreground text legible over busy content.
    var isOpaque: Bool = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(iOS 26, *) {
            content
                .background { shape.fill(Constants.Colors.white.opacity(isOpaque ? 0.55 : 0.001)) }
                .contentShape(shape)
                .glassEffect(.regular, in: shape)
        } else {
            content
                .background { shape.fill(Constants.Colors.white.opacity(0.001)) }
                .contentShape(shape)
                .background(
                    isOpaque ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.ultraThinMaterial),
                    in: shape
                )
        }
    }
}

// MARK: - View Extension

extension View {

    /// Gives a floating toolbar control a Liquid Glass background that also claims
    /// its whole shape for hit testing. See `GlassToolbarModifier`.
    func glassToolbarBackground(cornerRadius: CGFloat = 999, isOpaque: Bool = false) -> some View {
        modifier(GlassToolbarModifier(cornerRadius: cornerRadius, isOpaque: isOpaque))
    }
}
