//
//  CompletedTransactionView.swift
//  Resell
//
//  Created by Charles Liggins on 1/27/26.
//

import Kingfisher
import SwiftUI

struct CompletedTransactionView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var router: Router
    
    let transaction: Transaction // should be renamed as this is part of a swift library already...
    
    @State private var stars: Int = 0
    @State private var reviewFeedback: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showSuccessAlert: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    private var canSubmit: Bool {
        stars > 0
    }
    
    // MARK: - UI
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Transaction summary card
                transactionSummaryCard
                
                Divider()
                    .padding(.horizontal)
                
                // Review section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Leave a Review")
                        .font(.custom("Rubik-Medium", size: 20))
                        .foregroundColor(.black)
                    
                    Text("How was your experience with \(transaction.seller?.username ?? "the seller")?")
                        .font(.custom("Rubik-Regular", size: 14))
                        .foregroundColor(Constants.Colors.secondaryGray)
                    
                    // Star rating
                    starRatingView
                    
                    // Review text field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Comments (optional)")
                            .font(.custom("Rubik-Medium", size: 14))
                            .foregroundColor(Constants.Colors.secondaryGray)
                        
                        TextEditor(text: $reviewFeedback)
                            .frame(height: 120)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Constants.Colors.stroke, lineWidth: 1)
                            )
                            .font(.custom("Rubik-Regular", size: 14))
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
                
                // Submit button
                PurpleButton(isActive: canSubmit, text: isSubmitting ? "Submitting..." : "Submit Review") {
                    submitReview()
                }
                .disabled(!canSubmit || isSubmitting)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .padding(.top, 16)
        }
        .background(Constants.Colors.white)
        .navigationTitle("Transaction Complete")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Review Submitted!", isPresented: $showSuccessAlert) {
            Button("OK") {
                router.pop()
            }
        } message: {
            Text("Thank you for your feedback!")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Subviews
    
    private var transactionSummaryCard: some View {
        HStack(alignment: .top, spacing: 12) {
            // Post image
            KFImage(transaction.post?.firstImageURL)
                .placeholder {
                    ShimmerView()
                        .frame(width: 80, height: 80)
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(transaction.post?.title ?? "Item")
                    .font(.custom("Rubik-Medium", size: 16))
                    .foregroundColor(.black)
                    .lineLimit(2)
                
                Text(formattedAmount)
                    .font(.custom("Rubik-Medium", size: 18))
                    .foregroundColor(Constants.Colors.resellPurple)
                
                HStack(spacing: 4) {
                    if let photoURL = transaction.seller?.photoURL {
                        KFImage(photoURL)
                            .placeholder {
                                Circle().fill(Color.gray.opacity(0.3))
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                    }
                    
                    Text(transaction.seller?.username ?? "Seller")
                        .font(.custom("Rubik-Regular", size: 12))
                        .foregroundColor(Constants.Colors.secondaryGray)
                }
                
                Text("Purchased \(formattedDate)")
                    .font(.custom("Rubik-Regular", size: 11))
                    .foregroundColor(Constants.Colors.secondaryGray)
            }
            
            Spacer()
            
            Label("Completed", systemImage: "checkmark.circle.fill")
                .font(.custom("Rubik-Medium", size: 10))
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private var starRatingView: some View {
        HStack(spacing: 8) {
            ForEach(1...5, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        stars = index
                    }
                } label: {
                    Image(systemName: index <= stars ? "star.fill" : "star")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 36, height: 36)
                        .foregroundColor(index <= stars ? .yellow : Constants.Colors.secondaryGray.opacity(0.5))
                }
            }
            
            Spacer()
            
            if stars > 0 {
                Text(ratingText)
                    .font(.custom("Rubik-Medium", size: 14))
                    .foregroundColor(Constants.Colors.secondaryGray)
            }
        }
    }
    
    private var ratingText: String {
        switch stars {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Great"
        case 5: return "Excellent"
        default: return ""
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: transaction.transactionDate)
    }
    
    private var formattedAmount: String {
        String(format: "$%.2f", transaction.amount)
    }
    
    // MARK: - Functions
    
    private func submitReview() {
        guard canSubmit else { return }
        
        isSubmitting = true
        
        Task {
            do {
                // Create transaction review
                let reviewBody = CreateTransactionReviewBody(
                    transactionId: transaction.id,
                    stars: stars,
                    comments: reviewFeedback.isEmpty ? nil : reviewFeedback,
                    hadIssues: false,
                    issueCategory: nil,
                    issueDetails: nil
                )
                
                _ = try await NetworkManager.shared.createTransactionReview(review: reviewBody)
                
                // Also create a user review for the seller (only if we have buyer/seller info)
                if let buyerId = transaction.buyer?.firebaseUid,
                   let sellerId = transaction.seller?.firebaseUid {
                    let userReviewBody = CreateUserReviewBody(
                        buyerId: buyerId,
                        sellerId: sellerId,
                        fulfilled: true,
                        stars: stars,
                        comments: reviewFeedback.isEmpty ? "Great transaction!" : reviewFeedback
                    )
                    _ = try await NetworkManager.shared.createUserReview(review: userReviewBody)
                }
                
                await MainActor.run {
                    isSubmitting = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "Failed to submit review. Please try again."
                    showErrorAlert = true
                }
                NetworkManager.shared.logger.error("Error submitting review: \(error.localizedDescription)")
            }
        }
    }
}
