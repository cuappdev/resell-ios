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
                .background { shape.fill(Color.white.opacity(isOpaque ? 0.55 : 0.001)) }
                .contentShape(shape)
                .glassEffect(.regular, in: shape)
        } else {
            content
                .background { shape.fill(Color.white.opacity(0.001)) }
                .contentShape(shape)
                .background(
                    isOpaque ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.ultraThinMaterial),
                    in: shape
                )
        }
    }
}
