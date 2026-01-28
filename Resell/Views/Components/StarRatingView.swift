//
//  StarRatingView.swift
//  Resell
//
//  Created by Charles Liggins on 1/28/26.
//

import SwiftUI

/// A view that displays a star rating (supports fractional ratings)
struct StarRatingView: View {
    let rating: Double
    let maxRating: Int
    let starSize: CGFloat
    let filledColor: Color
    let emptyColor: Color
    
    init(
        rating: Double,
        maxRating: Int = 5,
        starSize: CGFloat = 12,
        filledColor: Color = .yellow,
        emptyColor: Color = Constants.Colors.inactiveGray
    ) {
        self.rating = rating
        self.maxRating = maxRating
        self.starSize = starSize
        self.filledColor = filledColor
        self.emptyColor = emptyColor
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                starView(for: index)
            }
        }
    }
    
    @ViewBuilder
    private func starView(for index: Int) -> some View {
        let fillAmount = min(max(rating - Double(index - 1), 0), 1)
        
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Empty star background
                Image(systemName: "star.fill")
                    .resizable()
                    .foregroundColor(emptyColor)
                
                // Filled star overlay (clipped based on fill amount)
                Image(systemName: "star.fill")
                    .resizable()
                    .foregroundColor(filledColor)
                    .mask(
                        Rectangle()
                            .frame(width: geometry.size.width * fillAmount)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    )
            }
        }
        .frame(width: starSize, height: starSize)
    }
}

#Preview {
    VStack(spacing: 20) {
        StarRatingView(rating: 0)
        StarRatingView(rating: 2.5)
        StarRatingView(rating: 3.7)
        StarRatingView(rating: 4.2)
        StarRatingView(rating: 5)
        
        // Larger version
        StarRatingView(rating: 4.3, starSize: 24)
    }
    .padding()
}
