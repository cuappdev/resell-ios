//
//  ReviewSection.swift
//  Resell
//
//  Created by Charles Liggins on 12/30/25.
//

import Kingfisher
import SwiftUI

struct ReviewSection: View {
    let reviews: [TransactionReview]
    
    var body: some View {
        if reviews.isEmpty {
            emptyState
        } else {
            LazyVStack(spacing: 16) {
                ForEach(reviews) { review in
                    TransactionReviewCard(review: review)
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

struct TransactionReviewCard: View {
    let review: TransactionReview
    
    private var buyer: UserSummary? {
        review.transaction?.buyer
    }
    
    private var post: PostSummary? {
        review.transaction?.post
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Reviewer (buyer) profile image
                if let photoUrl = buyer?.photoUrl, let url = URL(string: photoUrl) {
                    KFImage(url)
                        .placeholder {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Constants.Colors.wash)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(Constants.Colors.inactiveGray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Reviewer name
                    Text(buyer?.givenName ?? "Anonymous")
                        .font(Constants.Fonts.title3)
                        .foregroundColor(Constants.Colors.black)
                    
                    // Star rating
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= review.stars ? "star.fill" : "star")
                                .resizable()
                                .frame(width: 12, height: 12)
                                .foregroundColor(index <= review.stars ? Constants.Colors.resellPurple : Constants.Colors.inactiveGray)
                        }
                    }
                }
                
                Spacer()
                
                // Date
                if let createdAt = review.createdAt {
                    Text(formatDate(createdAt))
                        .font(Constants.Fonts.body2)
                        .foregroundColor(Constants.Colors.inactiveGray)
                }
            }
            
            // Review comment
            if let comments = review.comments, !comments.isEmpty {
                Text(comments)
                    .font(Constants.Fonts.body2)
                    .foregroundColor(Constants.Colors.black)
                    .lineLimit(3)
            }
            
            // Post info (what was purchased)
            if let post = post {
                HStack(spacing: 8) {
                    if let imageUrl = post.firstImageURL {
                        KFImage(imageUrl)
                            .placeholder {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    Text("Purchased: \(post.title)")
                        .font(Constants.Fonts.body2)
                        .foregroundColor(Constants.Colors.secondaryGray)
                        .lineLimit(1)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Constants.Colors.stroke, lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
