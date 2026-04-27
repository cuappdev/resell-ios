//
//  ReviewTestingView.swift
//  Resell
//
//  Debug view for rapidly testing review creation and inspecting date handling.
//

import SwiftUI
import Kingfisher

struct ReviewTestingView: View {
    
    @EnvironmentObject var router: Router
    
    // MARK: - State
    
    @State private var buyerTransactions: [Transaction] = []
    @State private var sellerTransactions: [Transaction] = []
    @State private var transactionReviews: [TransactionReview] = []
    @State private var isLoadingTransactions = false
    @State private var isLoadingReviews = false
    @State private var errorMessage: String?
    
    // Quick review creation
    @State private var quickStars: Int = 4
    @State private var quickComment: String = "Test review from debug tool"
    @State private var isSubmitting = false
    @State private var submitResult: String?
    
    // Date debug
    @State private var rawResponseJSON: String?
    
    private var currentUserId: String {
        GoogleAuthManager.shared.user?.firebaseUid ?? "unknown"
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - User Info
                infoSection
                
                Divider()
                
                // MARK: - Quick Review Creator
                quickReviewSection
                
                Divider()
                
                // MARK: - Transactions (as buyer)
                buyerTransactionsSection
                
                Divider()
                
                // MARK: - Transactions (as seller)
                sellerTransactionsSection
                
                Divider()
                
                // MARK: - Existing Reviews (debug dates)
                existingReviewsSection
                
                Divider()
                
                // MARK: - Raw JSON
                if let raw = rawResponseJSON {
                    rawJSONSection(raw)
                }
            }
            .padding()
        }
        .background(Constants.Colors.white)
        .navigationTitle("Review Testing")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
        }
        .task {
            await loadAll()
        }
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Debug Info")
                .font(.custom("Rubik-Medium", size: 18))
                .foregroundColor(.black)
            
            Group {
                Text("User ID: ").fontWeight(.medium) + Text(currentUserId)
                Text("Username: ").fontWeight(.medium) + Text(GoogleAuthManager.shared.user?.username ?? "N/A")
            }
            .font(.custom("Rubik-Regular", size: 13))
            .foregroundColor(.black)
            .textSelection(.enabled)
        }
    }
    
    // MARK: - Quick Review Section
    
    private var quickReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Review Creator")
                .font(.custom("Rubik-Medium", size: 18))
                .foregroundColor(.black)
            
            Text("Select a transaction below, then tap 'Submit Review' to quickly create both a transaction review and a user review.")
                .font(.custom("Rubik-Regular", size: 13))
                .foregroundColor(Constants.Colors.secondaryGray)
            
            // Star picker
            HStack(spacing: 4) {
                Text("Stars:")
                    .font(.custom("Rubik-Medium", size: 14))
                ForEach(1...5, id: \.self) { i in
                    Button {
                        quickStars = i
                    } label: {
                        Image(systemName: i <= quickStars ? "star.fill" : "star")
                            .foregroundColor(i <= quickStars ? .yellow : .gray)
                    }
                }
            }
            
            TextField("Comment", text: $quickComment)
                .font(.custom("Rubik-Regular", size: 14))
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Constants.Colors.stroke, lineWidth: 1)
                )
            
            if let result = submitResult {
                Text(result)
                    .font(.custom("Rubik-Regular", size: 12))
                    .foregroundColor(result.contains("✅") ? .green : .red)
                    .textSelection(.enabled)
            }
        }
    }
    
    // MARK: - Buyer Transactions
    
    private var buyerTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Purchases (as buyer)")
                    .font(.custom("Rubik-Medium", size: 18))
                    .foregroundColor(.black)
                
                Spacer()
                
                if isLoadingTransactions {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if buyerTransactions.isEmpty && !isLoadingTransactions {
                Text("No transactions found as buyer.")
                    .font(.custom("Rubik-Regular", size: 13))
                    .foregroundColor(Constants.Colors.secondaryGray)
            } else {
                ForEach(buyerTransactions) { tx in
                    transactionRow(tx, isBuyer: true)
                }
            }
        }
    }
    
    // MARK: - Seller Transactions
    
    private var sellerTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Sales (as seller)")
                    .font(.custom("Rubik-Medium", size: 18))
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            if sellerTransactions.isEmpty && !isLoadingTransactions {
                Text("No transactions found as seller.")
                    .font(.custom("Rubik-Regular", size: 13))
                    .foregroundColor(Constants.Colors.secondaryGray)
            } else {
                ForEach(sellerTransactions) { tx in
                    transactionRow(tx, isBuyer: false)
                }
            }
        }
    }
    
    // MARK: - Transaction Row
    
    private func transactionRow(_ tx: Transaction, isBuyer: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                // Post thumbnail
                if let url = tx.post?.firstImageURL {
                    KFImage(url)
                        .placeholder { Rectangle().fill(Color.gray.opacity(0.2)) }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tx.post?.title ?? "Unknown Item")
                        .font(.custom("Rubik-Medium", size: 14))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    Text("$\(String(format: "%.2f", tx.amount))")
                        .font(.custom("Rubik-Medium", size: 13))
                        .foregroundColor(Constants.Colors.resellPurple)
                    
                    // Date debug info
                    Text("Date: \(tx.transactionDate, formatter: iso8601Formatter)")
                        .font(.custom("Rubik-Regular", size: 11))
                        .foregroundColor(.orange)
                    
                    Text("Completed: \(tx.completed ? "Yes" : "No")")
                        .font(.custom("Rubik-Regular", size: 11))
                        .foregroundColor(tx.completed ? .green : .red)
                }
                
                Spacer()
                
                VStack(spacing: 6) {
                    // Navigate to full CompletedTransactionView
                    Button {
                        router.push(.completedTransaction(tx))
                    } label: {
                        Text("Open")
                            .font(.custom("Rubik-Medium", size: 11))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Constants.Colors.resellPurple)
                            .clipShape(Capsule())
                    }
                    
                    // Quick submit review
                    Button {
                        Task { await quickSubmitReview(for: tx) }
                    } label: {
                        Text(isSubmitting ? "..." : "Review")
                            .font(.custom("Rubik-Medium", size: 11))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                    .disabled(isSubmitting)
                }
            }
            
            // Debug: transaction ID
            Text("ID: \(tx.id)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray)
                .textSelection(.enabled)
            
            if isBuyer {
                Text("Seller: \(tx.seller?.username ?? "N/A") (\(tx.seller?.firebaseUid ?? "no uid"))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
                    .textSelection(.enabled)
            } else {
                Text("Buyer: \(tx.buyer?.username ?? "N/A") (\(tx.buyer?.firebaseUid ?? "no uid"))")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
                    .textSelection(.enabled)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Constants.Colors.stroke, lineWidth: 1)
        )
    }
    
    // MARK: - Existing Reviews
    
    private var existingReviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Existing Transaction Reviews")
                    .font(.custom("Rubik-Medium", size: 18))
                    .foregroundColor(.black)
                
                Spacer()
                
                Button {
                    Task { await fetchReviews() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Constants.Colors.resellPurple)
                }
                
                if isLoadingReviews {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if transactionReviews.isEmpty && !isLoadingReviews {
                Text("No reviews found.")
                    .font(.custom("Rubik-Regular", size: 13))
                    .foregroundColor(Constants.Colors.secondaryGray)
            } else {
                ForEach(transactionReviews) { review in
                    reviewDebugCard(review)
                }
            }
        }
    }
    
    // MARK: - Review Debug Card
    
    private func reviewDebugCard(_ review: TransactionReview) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                // Stars
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= review.stars ? "star.fill" : "star")
                            .resizable()
                            .frame(width: 14, height: 14)
                            .foregroundColor(i <= review.stars ? .yellow : .gray)
                    }
                }
                
                Spacer()
                
                // Date display
                if let createdAt = review.createdAt {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Parsed: \(createdAt, formatter: iso8601Formatter)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.green)
                        
                        Text("Display: \(formatDate(createdAt))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                } else {
                    Text("⚠️ createdAt is nil")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.red)
                }
            }
            
            if let comments = review.comments, !comments.isEmpty {
                Text(comments)
                    .font(.custom("Rubik-Regular", size: 13))
                    .foregroundColor(.black)
            }
            
            // Debug fields
            Group {
                Text("Review ID: \(review.id)")
                Text("hadIssues: \(review.hadIssues ? "true" : "false")")
                if let cat = review.issueCategory { Text("issueCategory: \(cat)") }
                if let tx = review.transaction {
                    Text("Transaction ID: \(tx.id)")
                    Text("Transaction Date: \(tx.transactionDate, formatter: iso8601Formatter)")
                    if let buyer = tx.buyer {
                        Text("Buyer: \(buyer.username) (\(buyer.firebaseUid))")
                    }
                    if let seller = tx.seller {
                        Text("Seller: \(seller.username) (\(seller.firebaseUid))")
                    }
                } else {
                    Text("⚠️ transaction is nil in review response")
                        .foregroundColor(.orange)
                }
            }
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(.gray)
            .textSelection(.enabled)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Raw JSON Section
    
    private func rawJSONSection(_ json: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Last Raw API Response")
                    .font(.custom("Rubik-Medium", size: 16))
                    .foregroundColor(.black)
                
                Spacer()
                
                Button {
                    rawResponseJSON = nil
                } label: {
                    Text("Clear")
                        .font(.custom("Rubik-Regular", size: 12))
                        .foregroundColor(.red)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: true) {
                Text(json)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.black)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 200)
            .padding(8)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Data Loading
    
    private func loadAll() async {
        isLoadingTransactions = true
        
        async let buyerTask: () = fetchBuyerTransactions()
        async let sellerTask: () = fetchSellerTransactions()
        async let reviewsTask: () = fetchReviews()
        
        _ = await (buyerTask, sellerTask, reviewsTask)
        
        isLoadingTransactions = false
    }
    
    private func fetchBuyerTransactions() async {
        do {
            let response = try await NetworkManager.shared.getTransactionsByBuyerId(userId: currentUserId)
            await MainActor.run {
                buyerTransactions = response.transactions
            }
        } catch {
            print("❌ Error fetching buyer transactions: \(error)")
            await MainActor.run {
                errorMessage = "Buyer transactions: \(error.localizedDescription)"
            }
        }
    }
    
    private func fetchSellerTransactions() async {
        do {
            let response = try await NetworkManager.shared.getTransactionsBySellerId(userId: currentUserId)
            await MainActor.run {
                sellerTransactions = response.transactions
            }
        } catch {
            print("❌ Error fetching seller transactions: \(error)")
        }
    }
    
    private func fetchReviews() async {
        isLoadingReviews = true
        do {
            let reviews = try await NetworkManager.shared.getReviewsForSeller(sellerId: currentUserId)
            await MainActor.run {
                transactionReviews = reviews
                isLoadingReviews = false
            }
        } catch {
            print("❌ Error fetching reviews: \(error)")
            await MainActor.run {
                isLoadingReviews = false
            }
        }
    }
    
    // MARK: - Quick Submit
    
    private func quickSubmitReview(for tx: Transaction) async {
        await MainActor.run {
            isSubmitting = true
            submitResult = nil
        }
        
        do {
            // 1. Create transaction review
            let reviewBody = CreateTransactionReviewBody(
                transactionId: tx.id,
                stars: quickStars,
                comments: quickComment.isEmpty ? nil : quickComment,
                hadIssues: false,
                issueCategory: nil,
                issueDetails: nil
            )
            
            let txReviewResponse = try await NetworkManager.shared.createTransactionReview(review: reviewBody)
            
            var userReviewResult = "skipped (no buyer/seller IDs)"
            
            // 2. Create user review if we have IDs
            if let buyerId = tx.buyer?.firebaseUid,
               let sellerId = tx.seller?.firebaseUid {
                let userReviewBody = CreateUserReviewBody(
                    buyerId: buyerId,
                    sellerId: sellerId,
                    fulfilled: true,
                    stars: quickStars,
                    comments: quickComment.isEmpty ? "Test review" : quickComment
                )
                let userResponse = try await NetworkManager.shared.createUserReview(review: userReviewBody)
                userReviewResult = "created (id: \(userResponse.review.id))"
            }
            
            await MainActor.run {
                isSubmitting = false
                submitResult = """
                ✅ Success!
                Transaction Review ID: \(txReviewResponse.review.id)
                createdAt: \(txReviewResponse.review.createdAt.map { iso8601Formatter.string(from: $0) } ?? "nil")
                User Review: \(userReviewResult)
                """
            }
            
            // Refresh reviews list
            await fetchReviews()
            
        } catch {
            await MainActor.run {
                isSubmitting = false
                submitResult = "❌ Error: \(error.localizedDescription)"
            }
            print("❌ Quick review submit error: \(error)")
        }
    }
    
    // MARK: - Helpers
    
    private var iso8601Formatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
