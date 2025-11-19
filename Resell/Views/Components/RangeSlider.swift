//
//  RangeSlider.swift
//  Resell
//
//  Created by Charles Liggins on 10/13/25.
//

import SwiftUI

struct RangeSlider: View {
    @Binding var lowValue: Double
    @Binding var highValue: Double
    let range: ClosedRange<Double>
    let step: Double = 5 // Define the step value
    
    // Track width constant
    private let trackWidth: CGFloat = 344
    private let handleDiameter: CGFloat = 14
    
    // Calculate position from value
    private func position(for value: Double) -> CGFloat {
        let percentage = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(percentage) * (trackWidth - handleDiameter)
    }
    
    // Calculate value from position
    private func value(for position: CGFloat) -> Double {
        let percentage = Double(position) / Double(trackWidth - handleDiameter)
        let value = percentage * (range.upperBound - range.lowerBound) + range.lowerBound
        return round(value / step) * step
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Rectangle()
                    .fill(Constants.Colors.resellPurple.opacity(0.2))
                    .frame(width: trackWidth, height: 4)
                    .cornerRadius(4)
                
                // Low handle
                Circle()
                    .fill(Color.white)
                    .frame(width: handleDiameter, height: handleDiameter)
                    .shadow(radius: 4)
                    .position(x: position(for: lowValue) + handleDiameter/2, y: geometry.size.height/2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPosition = min(max(0, value.location.x - handleDiameter/2), position(for: highValue) - handleDiameter)
                                let newValue = self.value(for: newPosition)
                                // Ensure minimum distance between handles
                                if newValue <= highValue - step {
                                    lowValue = newValue
                                }
                            }
                    )
                
                // High handle
                Circle()
                    .fill(Color.white)
                    .frame(width: handleDiameter, height: handleDiameter)
                    .shadow(radius: 4)
                    .position(x: position(for: highValue) + handleDiameter/2, y: geometry.size.height/2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPosition = min(max(position(for: lowValue) + handleDiameter, value.location.x - handleDiameter/2), trackWidth - handleDiameter)
                                let newValue = self.value(for: newPosition)
                                // Ensure minimum distance between handles
                                if newValue >= lowValue + step {
                                    highValue = newValue
                                }
                            }
                    )
            }
        }
        .frame(height: 44)
    }
}

