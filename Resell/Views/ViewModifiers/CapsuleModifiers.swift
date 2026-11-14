//
//  CapsuleModifiers.swift
//  Resell
//
//  Created by Andrew Gao on 11/13/26.
//

import SwiftUI

extension View {

    /// Styles the view as a primary action: white text on a Resell-purple capsule, faded while
    /// the enclosing button is disabled.
    func purpleCapsule(font: Font = Constants.Fonts.title1) -> some View {
        modifier(PurpleCapsule(font: font))
    }

    /// Puts the view on a white capsule outlined in `border`.
    func outlinedCapsule(_ border: some ShapeStyle, lineWidth: CGFloat) -> some View {
        modifier(OutlinedCapsule(border: border, lineWidth: lineWidth))
    }
}

struct PurpleCapsule: ViewModifier {

    private static let disabledOpacity: CGFloat = 0.4

    @Environment(\.isEnabled) private var isEnabled

    let font: Font

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(Constants.Colors.white)
            .background(Constants.Colors.resellPurple, in: Capsule())
            .opacity(isEnabled ? 1 : Self.disabledOpacity)
    }
}

/// A button drawn as `purpleCapsule()`. Unlike `.plain`, it adds no fade of its own while
/// disabled, so a disabled button shows the design's 40% instead of a doubled fade.
struct PurpleCapsuleButtonStyle: ButtonStyle {

    private static let pressedOpacity: CGFloat = 0.7

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .purpleCapsule()
            .opacity(configuration.isPressed ? Self.pressedOpacity : 1)
    }
}

extension ButtonStyle where Self == PurpleCapsuleButtonStyle {

    static var purpleCapsule: PurpleCapsuleButtonStyle { PurpleCapsuleButtonStyle() }
}

struct OutlinedCapsule<Border: ShapeStyle>: ViewModifier {

    let border: Border
    let lineWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .background(Constants.Colors.white, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(border, lineWidth: lineWidth)
            }
    }
}
