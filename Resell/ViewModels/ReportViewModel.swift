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
        isLoading = true

        Task {
            defer { Task { @MainActor in withAnimation { isLoading = false } } }

            do {
                if let userID = user?.firebaseUid,
                   let postID = post?.id {
                    let reportBody = ReportPostBody(reported: userID, post: postID, reason: selectedOption)
                    try await NetworkManager.shared.reportPost(reportBody: reportBody)
                }
            } catch {
                NetworkManager.shared.logger.error("Error in ReportViewModel.reportPost: \(error)")
            }
        }
    }

    func reportUser() {
        isLoading = true

        Task {
            defer { Task { @MainActor in withAnimation { isLoading = false } } }

            do {
                if let userID = user?.firebaseUid {
                    let reportBody = ReportUserBody(reported: userID, reason: selectedOption)
                    try await NetworkManager.shared.reportUser(reportBody: reportBody)
                }
            } catch {
                NetworkManager.shared.logger.error("Error in ReportViewModel.reportUser: \(error)")
            }
        }
    }

    func blockUser() {
        isLoading = true

        Task {
            defer { Task { @MainActor in withAnimation { isLoading = false } } }

            do {
                if let id = user?.firebaseUid {
                    let blocked = BlockUserBody(blocked: id)
                    try await NetworkManager.shared.blockUser(blocked: blocked)
                }
            } catch {
                NetworkManager.shared.logger.error("Error in ProfileViewModel.blockUser: \(error)")
            }
        }
    }

    func getUser(id: String) {
        Task {
            do {
                user = try await NetworkManager.shared.getUserByID(id: id).user
            } catch {
                NetworkManager.shared.logger.error("Error in ReportViewModel.getUser: \(error)")
            }
        }
    }

    func getPostUser(id: String) {
        Task {
            do {
                post = try await NetworkManager.shared.getPostByID(id: id).post
                user = post?.user
            } catch {
                NetworkManager.shared.logger.error("Error in ReportViewModel.getUser: \(error)")
            }
        }
    }

    func clear() {
        didShowPopup = false
        reportDetailsText = ""
        selectedOption = ""
    }

}
