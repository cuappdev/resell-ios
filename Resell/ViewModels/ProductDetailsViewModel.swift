//
//  ProductDetailsViewModel.swift
//  Resell
//
//  Created by Richie Sun on 10/17/24.
//

import SwiftUI
import UserNotifications

@MainActor
class ProductDetailsViewModel: ObservableObject {

    // MARK: - Properties

    @Published var didShowOptionsMenu: Bool = false
    @Published var didShowDeleteView: Bool = false

    @Published var currentPage: Int = 0
    @Published var images: [URL] = []

    @Published var isSaved: Bool = false
    @Published var maxDrag: CGFloat = UIScreen.height / 2
    @Published var maxImgRatio: CGFloat = 1.0
    @Published var item: Post?

    // MARK: - Functions

    func getPost(id: String) {
        Task {
            do {
                let postResponse = try await NetworkManager.shared.getPostByID(id: id)
                item = postResponse.post
                images = postResponse.post.images

                await calculateMaxImgRatio()
                getIsSaved()
            } catch {
                NetworkManager.shared.logger.error("Error in ProductDetailsViewModel.getPost: \(error.localizedDescription)")
            }
        }
    }

    func updateItemSaved() {
        Task {
            do {
                if let id = item?.id {
                    if !isSaved {
                        let _ = try await NetworkManager.shared.unsavePostByID(id: id)
                    } else {
                        let _ = try await NetworkManager.shared.savePostByID(id: id)
                    }
                }
            } catch {
                NetworkManager.shared.logger.error("Error in ProductDetailsViewModel:.updateItemSaved \(error.localizedDescription)")
            }
        }
    }

    func getIsSaved() {
        Task {
            do {
                if let id = item?.id {
                    isSaved = try await NetworkManager.shared.postIsSaved(id: id).isSaved
                }
            } catch {
                NetworkManager.shared.logger.error("Error in ProductDetailsViewModel.getIsSaved: \(error.localizedDescription)")
            }
        }
    }

    func archivePost() {
        Task {
            do {
                if let id = item?.id {
                    let _ = try await NetworkManager.shared.archivePost(id: id)
                }

                didShowDeleteView = false
            } catch {
                NetworkManager.shared.logger.error("Error in ProductDetailsViewModel.archivePost: \(error.localizedDescription)")
            }
        }
    }

    func deletePost() {
        Task {
            do {
                if let id = item?.id {
                    try await NetworkManager.shared.deletePost(id: id)
                }

                didShowDeleteView = false
            } catch {
                NetworkManager.shared.logger.error("Error in ProductDetailsViewModel.deletePost: \(error.localizedDescription)")
            }
        }
    }

    func isUserPost() -> Bool {
        if let userId = UserSessionManager.shared.userID,
           let itemUserId = item?.user?.id {
            return userId == itemUserId
        }

        return false
    }

    func changeItem() {
        // TODO: Backend Call to change item to similar item
    }
    
//    // Creates a new notification for type = bookmarks
//    // __(person)__ has bookmarked __(item)__
    
//    func createNewNotif() {
//        Task {
//            do {
//                // Checks product exists
//                guard let product = item else {
//                    NetworkManager.shared.logger.error("Error in createNewNotif: Product not available.")
//                        return
//                }
//                
//                guard let userID = UserSessionManager.shared.userID else {
//                    UserSessionManager.shared.logger.error("Error in createNewNotif: userID not found")
//                    return
//                }
//                
//                // Checks
//                guard let sellerID = product.user?.id else {
//                    NetworkManager.shared.logger.error("Error in createNewNotif: Seller ID not found.")
//                        return
//                }
//                
//                let productName = product.title
//                
//                // Posts a notification under the sellerID
//                let notification = Notification(
//                    userID: sellerID,
//                    title: "\(userID) has bookmarked \(productName)",
//                    body: "\(productName) was bookmarked!",
//                    data: NotificationData(type: "bookmarks", messageId: UUID().uuidString)
//                )
//                
//                let _ = try await NetworkManager.shared.createNotif(notifBody: notification)
//                
//                NetworkManager.shared.logger.info("Notification sent!!")
//            } catch {
//
//                NetworkManager.shared.logger.error("Error in ProductDetailsViewModel.createNewNotif: \(error.localizedDescription)")
//
//            }
//        }
//    }
    
    func createNewNotif() {
        print(UserSessionManager.shared.userID)
        Task {
            do {
                guard let product = item else {
                    NetworkManager.shared.logger.error("Error: Product details not available.")
                    return
                }

                guard let sellerID = product.user?.id else {
                    NetworkManager.shared.logger.error("Error: Seller ID not found.")
                    return
                }

                let productName = product.title

                let notification = Notification(
                    userID: sellerID,
                    title: "\(UserSessionManager.shared.userID ?? "Someone") has bookmarked \(productName)",
                    body: "Your item '\(productName)' was bookmarked!",
                    data: NotificationData(type: "bookmarks", messageId: UUID().uuidString)
                )

                try await NetworkManager.shared.createNotif(notifBody: notification)
                NetworkManager.shared.logger.info("Notification sent successfully!")

            } catch let error as ErrorResponse {
                // Specific error from app
                NetworkManager.shared.logger.error("API Error \(error.localizedDescription)")
            } catch {
                // General error
                NetworkManager.shared.logger.error("Unexpected error \(error.localizedDescription)")
            }
        }
    }


    private func calculateMaxImgRatio() async {
        var maxRatio = 0.0
        for imageUrl in images {
            guard let data = try? await URLSession.shared.data(from: imageUrl).0,
                  let image = UIImage(data: data) else { continue }

            let aspectRatio = image.aspectRatio

            maxRatio = max(maxRatio, aspectRatio)
        }

        withAnimation {
            maxImgRatio = maxRatio
        }
    }
}
