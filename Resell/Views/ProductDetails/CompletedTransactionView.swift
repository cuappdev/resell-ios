//
//  CompletedTransactionView.swift
//  Resell
//
//  Created by Charles Liggins on 1/27/26.
//

import Kingfisher
import SwiftUI

// MARK: - Flow Layout (wrapping horizontal layout)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        
        return CGSize(width: maxWidth, height: currentY + rowHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct CompletedTransactionView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var router: Router
    
    let transaction: Transaction // should be renamed as this is part of a swift library already...
    
    @State private var stars: Int = 0
    @State private var reviewFeedback: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var isSubmitting: Bool = false
    @State private var showSuccessAlert: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    private let sellerTags = ["Friendly", "Punctual", "Responsive", "Slow response", "Fair pricing", "As described"]
    
    private var canSubmit: Bool {
        stars > 0
    }
    
    // MARK: - UI
    
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Transaction summary card
                    transactionSummaryCard
                    
                    Divider()
                    
                    // Review section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Transaction Review")
                            .font(Constants.Fonts.h3)
                            .foregroundColor(.black)
                        
                        // Star rating
                        starRatingView
                        
                        // Review text field with inline placeholder
                        ZStack(alignment: .topLeading) {
                            if reviewFeedback.isEmpty {
                                Text("How was your transaction experience with \(transaction.seller?.fullName ?? transaction.seller?.username ?? "the seller")? (optional)")
                                    .font(Constants.Fonts.body2)
                                    .foregroundColor(Constants.Colors.secondaryGray)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                            }
                            
                            TextEditor(text: $reviewFeedback)
                                .frame(height: 140)
                                .font(Constants.Fonts.body2)
                                .foregroundColor(Constants.Colors.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .scrollContentBackground(.hidden)
                                .focused($isTextEditorFocused)
                        }
                        .background(Constants.Colors.wash)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Seller tags
                        sellerTagsView
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            .onTapGesture {
                isTextEditorFocused = false
            }
            
            // Submit button pinned to bottom
            PurpleButton(isActive: canSubmit, text: isSubmitting ? "Submitting..." : "Submit Review") {
                submitReview()
            }
            .disabled(!canSubmit || isSubmitting)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .padding(.top, 12)
        }
        .background(Constants.Colors.white)
        .navigationTitle("Completed Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Review Submitted!", isPresented: $showSuccessAlert) {
            Button("OK") {
                router.pop()
            }
        } message: {
            Text("Thank you for your feedback!")
        }
        .alert("Couldn’t submit review", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Subviews
    
    private var transactionSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Purchase Summary")
                .font(Constants.Fonts.h3)
                .foregroundStyle(.black)
            
            HStack(spacing: 16) {
                // Post image
                KFImage(transaction.post?.firstImageURL)
                    .placeholder {
                        ShimmerView()
                            .frame(width: 80, height: 80)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 0) {
                        Text(transaction.post?.title ?? "Item")
                            .font(Constants.Fonts.title1)
                            .foregroundColor(.black)
                        
                        Text(" • ")
                            .font(Constants.Fonts.body1)
                            .foregroundColor(.black)
                        
                        Text(formattedAmount)
                            .font(Constants.Fonts.body1)
                            .foregroundColor(Constants.Colors.black)
                    }
                    
                    Text("Sold by \(transaction.seller?.username ?? "Seller")")
                        .font(Constants.Fonts.body2)
                        .foregroundColor(Constants.Colors.black)
                    
                    Text("Purchased \(formattedDate)")
                        .font(.custom("Rubik-Regular", size: 11))
                        .foregroundColor(Constants.Colors.black)
                }
            }
        }
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
                        .foregroundColor(index <= stars ? Constants.Colors.resellPurple : Constants.Colors.secondaryGray.opacity(0.5))
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
    
    private var sellerTagsView: some View {
        FlowLayout(spacing: 8) {
            ForEach(sellerTags, id: \.self) { tag in
                let isSelected = selectedTags.contains(tag)
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if isSelected {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }
                } label: {
                    Text(tag)
                        .font(.custom("Rubik-Regular", size: 14))
                        .foregroundColor(isSelected ? Constants.Colors.resellPurple : Constants.Colors.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? Constants.Colors.resellPurple.opacity(0.25) : Color.clear)
                        )
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Constants.Colors.resellPurple : Constants.Colors.stroke, lineWidth: 1)
                        )
                }
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
                // Require buyer and seller before doing anything — this prevents
                // creating an orphan transaction review for a transaction that
                // can't produce a valid (filterable) user review.
                guard let buyerId = transaction.buyer?.firebaseUid,
                      let sellerId = transaction.seller?.firebaseUid,
                      !buyerId.isEmpty, !sellerId.isEmpty else {
                    NetworkManager.shared.logger.error("submitReview aborted: transaction \(transaction.id) is missing buyer or seller info")
                    await MainActor.run {
                        isSubmitting = false
                        errorMessage = "This transaction is missing buyer or seller info, so it can't be reviewed yet."
                        showErrorAlert = true
                    }
                    return
                }
                
                let reviewBody = CreateTransactionReviewBody(
                    transactionId: transaction.id,
                    stars: stars,
                    comments: reviewFeedback.isEmpty ? nil : reviewFeedback,
                    hadIssues: false,
                    issueCategory: nil,
                    issueDetails: nil
                )
                
                _ = try await NetworkManager.shared.createTransactionReview(review: reviewBody)
                
                let userReviewBody = CreateUserReviewBody(
                    buyerId: buyerId,
                    sellerId: sellerId,
                    fulfilled: true,
                    stars: stars,
                    comments: reviewFeedback.isEmpty ? "Great transaction!" : reviewFeedback
                )
                _ = try await NetworkManager.shared.createUserReview(review: userReviewBody)
                
                await MainActor.run {
                    isSubmitting = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.resellUserFacingDescription
                    showErrorAlert = true
                }
                NetworkManager.shared.logger.error("Error submitting review: \(error.localizedDescription)")
            }
        }
    }
}
