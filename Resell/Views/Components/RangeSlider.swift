//
//  RangeSlider.swift
//  Resell
//
//  Created by Charles Liggins on 10/13/25.
//

import SwiftUI

struct RangeSlider: View {

    // MARK: - Properties

    @Binding var lowValue: Double
    @Binding var highValue: Double
    let range: ClosedRange<Double>
    let step: Double = 5

    private let trackWidth: CGFloat = 344
    private let trackHeight: CGFloat = 4
    private let handleDiameter: CGFloat = 14

    private var lowHandleX: CGFloat {
        position(for: lowValue) + handleDiameter / 2
    }

    private var highHandleX: CGFloat {
        position(for: highValue) + handleDiameter / 2
    }

    // MARK: - UI

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                track
                lowHandle(centerY: geometry.size.height / 2)
                highHandle(centerY: geometry.size.height / 2)
            }
        }
        .frame(height: 44)
    }

    private var track: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(Constants.Colors.resellPurple.opacity(0.2))
                .frame(width: trackWidth, height: trackHeight)
                .cornerRadius(trackHeight)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Constants.Colors.resellPurple.opacity(0.5),
                            Constants.Colors.resellPurple
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: max(0, highHandleX - lowHandleX), height: trackHeight)
                .offset(x: lowHandleX)
        }
    }

    private func lowHandle(centerY: CGFloat) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: handleDiameter, height: handleDiameter)
            .shadow(radius: 4)
            .position(x: lowHandleX, y: centerY)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newPosition = min(max(0, value.location.x - handleDiameter / 2), position(for: highValue) - handleDiameter)
                        let newValue = self.value(for: newPosition)
                        if newValue <= highValue - step {
                            lowValue = newValue
                        }
                    }
            )
    }

    private func highHandle(centerY: CGFloat) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: handleDiameter, height: handleDiameter)
            .shadow(radius: 4)
            .position(x: highHandleX, y: centerY)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newPosition = min(max(position(for: lowValue) + handleDiameter, value.location.x - handleDiameter / 2), trackWidth - handleDiameter)
                        let newValue = self.value(for: newPosition)
                        if newValue >= lowValue + step {
                            highValue = newValue
                        }
                    }
            )
    }

    // MARK: - Helpers

    private func position(for value: Double) -> CGFloat {
        let percentage = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(percentage) * (trackWidth - handleDiameter)
    }

    private func value(for position: CGFloat) -> Double {
        let percentage = Double(position) / Double(trackWidth - handleDiameter)
        let value = percentage * (range.upperBound - range.lowerBound) + range.lowerBound
        return round(value / step) * step
    }
}
