//
//  TransactionConfirmationPopup.swift
//  Resell
//
//  Created on 1/27/26.
//

import SwiftUI

struct TransactionConfirmationPopup: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var router: Router
    @Binding var isPresented: Bool
    
    let notification: Notifications
    let onConfirm: (Bool, Transaction?) -> Void
    
    @State private var isLoading = false
    
    private var postTitle: String {
        notification.data.postTitle ?? "this item"
    }
    
    private var sellerName: String {
        notification.data.sellerUsername ?? "the seller"
    }
    
    // MARK: - UI
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isLoading {
                        isPresented = false
                    }
                }
            
            // Popup card
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Constants.Colors.resellPurple)
                    
                    Text("Confirm Transaction")
                        .font(.custom("Rubik-Medium", size: 22))
                        .foregroundColor(.black)
                }
                
                // Description
                Text("Did your meetup for **\(postTitle)** with **\(sellerName)** happen?")
                    .font(.custom("Rubik-Regular", size: 16))
                    .foregroundColor(Constants.Colors.secondaryGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                
                // Buttons
                VStack(spacing: 12) {
                    // Confirm button
                    Button {
                        handleConfirmation(completed: true)
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark")
                                Text("Yes, it happened!")
                            }
                        }
                        .font(.custom("Rubik-Medium", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Constants.Colors.resellPurple)
                        .cornerRadius(24)
                    }
                    .disabled(isLoading)
                    
                    // Deny button
                    Button {
                        handleConfirmation(completed: false)
                    } label: {
                        HStack {
                            Image(systemName: "xmark")
                            Text("No, it didn't happen")
                        }
                        .font(.custom("Rubik-Medium", size: 16))
                        .foregroundColor(Constants.Colors.secondaryGray)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(24)
                    }
                    .disabled(isLoading)
                    
                    // Later button
                    Button {
                        isPresented = false
                    } label: {
                        Text("Remind me later")
                            .font(.custom("Rubik-Regular", size: 14))
                            .foregroundColor(Constants.Colors.secondaryGray)
                    }
                    .disabled(isLoading)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Functions
    
    private func handleConfirmation(completed: Bool) {
        guard let transactionId = notification.data.transactionId else {
            // No transaction ID - just dismiss
            isPresented = false
            return
        }
        
        isLoading = true
        
        Task {
            do {
                var transaction: Transaction? = nil
                
                if completed {
                    // Complete the transaction and get the updated transaction
                    let response = try await NetworkManager.shared.completeTransaction(transactionId: transactionId)
                    transaction = response.transaction
                }
                
                await MainActor.run {
                    isLoading = false
                    isPresented = false
                    onConfirm(completed, transaction)
                    
                    // Navigate to completed transaction view if confirmed
                    if completed, let tx = transaction {
                        router.push(.completedTransaction(tx))
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    isPresented = false
                }
                NetworkManager.shared.logger.error("Error confirming transaction: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TransactionConfirmationPopup(
        isPresented: .constant(true),
        notification: Notifications(
            id: "test",
            userId: "user123",
            title: "Confirm your meetup",
            body: "Did your meetup happen?",
            data: NotificationData(
                type: "transaction_confirmation",
                postTitle: "iPhone 15 Pro",
                sellerUsername: "john_doe",
                transactionId: "tx123"
            ),
            read: false,
            createdAt: Date(),
            updatedAt: Date()
        ),
        onConfirm: { _, _ in }
    )
    .environmentObject(Router())
}
