//
//  CompletedTransactionView.swift
//  Resell
//
//  Created by Charles Liggins on 1/27/26.
//

import Kingfisher
import SwiftUI

struct CompletedTransactionView: View {
    
    let transaction: Transaction
    @State var stars = 0
    @State var reviewFeedback : String = ""
    
    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 12) {
                // Post image
                KFImage(transaction.post.firstImageURL)
                    .placeholder {
                        ShimmerView()
                            .frame(width: 75, height: 75)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 75, height: 75)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(transaction.post.title)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(formattedAmount)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Sold by \(transaction.seller.username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Purchased \(formattedDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            Text("Transaction Review")
            
            starButtons
            
            TextField("How was your transaction experience with \(transaction.seller.fullName)? (optional)", text:$reviewFeedback)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .frame(width: 366, height: 140)
                )
            
            Spacer()
            
            PurpleButton(text: "Submit Review") {
                // call submit review endpoint
            } 
        }
        .frame(width: 366)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Completed Transaction")
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .padding()
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: transaction.transactionDate)
    }
    
    private var formattedAmount: String {
        String(format: "$%.2f", transaction.amount)
    }
    
    private func setStars(star_idx: Int) -> Void {
        stars = star_idx
    }
    
    private var starButtons: some View {
        ForEach(1...5, id: \.self) { index in
            Button {
                setStars(star_idx: index)
            } label: {
                Image(systemName: "star")
                    .resizable()
                    .frame(width: 40, height: 40)
            }
        }
    }
    
}
