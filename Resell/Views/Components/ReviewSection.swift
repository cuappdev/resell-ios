//
//  ReviewSection.swift
//  Resell
//
//  Created by Charles Liggins on 12/30/25.
//

import Kingfisher
import SwiftUI

struct ReviewSection: View {
    let reviews: [UserReview]
    
    var body: some View {
        if reviews.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: 16) {
                ForEach(reviews) { review in
                    UserReviewCard(review: review)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.slash")
                .font(.system(size: 40))
                .foregroundColor(Constants.Colors.inactiveGray)
            
            Text("No Reviews Yet")
                .font(Constants.Fonts.body1)
                .foregroundColor(Constants.Colors.secondaryGray)
            
            Text("Reviews from buyers will appear here")
                .font(Constants.Fonts.body2)
                .foregroundColor(Constants.Colors.inactiveGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct UserReviewCard: View {
    let review: UserReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 4) {
                Text(review.buyer?.givenName ?? "Anonymous")
                        .font(Constants.Fonts.title3)
                        .foregroundColor(Constants.Colors.black)
                    
                Text("•")
                    .font(Constants.Fonts.body2)
                    .foregroundColor(Constants.Colors.black)
                
                if let dateString = review.date, let date = parseDate(dateString) {
                    Text(formatDate(date))
                            .font(Constants.Fonts.body2)
                            .foregroundColor(Constants.Colors.inactiveGray)
                    }
                
                Spacer()
                    
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= review.stars ? "star.fill" : "star")
                                .resizable()
                            .frame(width: 20, height: 20)
                                .foregroundColor(index <= review.stars ? Constants.Colors.resellPurple : Constants.Colors.inactiveGray)
                    }
                }
            }
            
            if let comments = review.comments, !comments.isEmpty {
                Text(comments)
                    .font(Constants.Fonts.body2)
                    .foregroundColor(Constants.Colors.black)
                    .lineLimit(3)
            }
        }
        .padding(16)
        .frame(width: 366, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Constants.Colors.stroke, lineWidth: 1)
        )
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        Transaction.parseDate(dateString)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
