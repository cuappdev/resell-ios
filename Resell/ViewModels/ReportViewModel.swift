//
//  ReportViewModel.swift
//  Resell
//
//  Created by Richie Sun on 10/19/24.
//

import SwiftUI

@MainActor
class ReportViewModel: ObservableObject {

    // MARK: - Properties

    @Published var didShowPopup: Bool = false
    @Published var isLoading: Bool = false

    @Published var reportDetailsText: String = "" {
        didSet {
            if reportDetailsText.count > 1000 {
                reportDetailsText = String(reportDetailsText.prefix(1000))
            }
        }
    }

    // TODO: Add Logic to change this later
    @Published var reportType: String = "Post"
    @Published var selectedOption: String = ""

    var user: User? = nil
    var post: Post? = nil

    var reportOptions = [
        "Fraudulent behavior",
        "Sale of Illegal items",
        "Hate speech or symbols",
        "Bullying or harassment",
        "Sexual misconduct or nudity",
        "Unauthorized use of intellectual property",
        "Other"
    ]

    // MARK: - Functions

    func reportMessage() {
        // TODO: Backend Report Call
    }

    func reportPost() {
        Task {
            isLoading = true

            do {
                if let userID = user?.id,
                   let postID = post?.id {
                    let reportBody = ReportPostBody(reported: userID, post: postID, reason: selectedOption)
                    try await NetworkManager.shared.reportPost(reportBody: reportBody)
                }

                withAnimation { isLoading = false }
            } catch {
                NetworkManager.shared.logger.error("Error in ReportViewModel.reportPost: \(error.localizedDescription)")
                withAnimation { isLoading = false }
            }
        }
    }

    func reportUser() {
        Task {
            isLoading = true

            do {
                if let userID = user?.id {
                    let reportBody = ReportUserBody(reported: userID, reason: selectedOption)
                    try await NetworkManager.shared.reportUser(reportBody: reportBody)
                }

                withAnimation { isLoading = false }
            } catch {
                NetworkManager.shared.logger.error("Error in ReportViewModel.reportUser: \(error.localizedDescription)")
                withAnimation { isLoading = false }
            }
        }
    }

    func blockUser() {
        Task {
            isLoading = true

            do {
                if let id = user?.id {
                    let blocked = BlockUserBody(blocked: id)
                    try await NetworkManager.shared.blockUser(blocked: blocked)
                }

                withAnimation { isLoading = false }
            } catch {
                NetworkManager.shared.logger.error("Error in ProfileViewModel.blockUser: \(error.localizedDescription)")
                withAnimation { isLoading = false }
            }
        }
    }

    func getUser(id: String) {
        Task {
            do {
                user = try await NetworkManager.shared.getUserByID(id: id).user
            } catch {
                NetworkManager.shared.logger.error("Error in ReportViewModel.getUser: \(error.localizedDescription)")
            }
        }
    }

    func getPostUser(id: String) {
        Task {
            do {
                post = try await NetworkManager.shared.getPostByID(id: id).post
                user = post?.user
            } catch {
                NetworkManager.shared.logger.error("Error in ReportViewModel.getUser: \(error.localizedDescription)")
            }
        }
    }

    func clear() {
        didShowPopup = false
        reportDetailsText = ""
        selectedOption = ""
    }

}
