//
//  ProductDetailsViewModel.swift
//  Resell
//
//  Created by Richie Sun on 10/17/24.
//

import SwiftUI
import Kingfisher
import UserNotifications

@MainActor
class ProductDetailsViewModel: ObservableObject {

    // MARK: - Properties

    @Published var didShowOptionsMenu: Bool = false
    @Published var didShowDeleteView: Bool = false
    @Published var isLoading: Bool = false
    @Published var isLoadingImages: Bool = false

    @Published var currentPage: Int = 0
    @Published var images: [URL] = []

    @Published var isSaved: Bool = false
    @Published var maxDrag: CGFloat = UIScreen.height / 2
    @Published var maxImgRatio: CGFloat = 1.0
    @Published var item: Post?
    @Published var similarPosts: [Post] = []

    // MARK: - Functions

    func getPost(id: String) {
        isLoading = true

        Task {
            defer { Task { @MainActor in withAnimation { isLoading = false } } }

            do {
                let postResponse = try await NetworkManager.shared.getPostByID(id: id)
                item = postResponse.post
                images = postResponse.post.images.compactMap { URL(string: $0) }

                await calculateMaxImgRatio()
                getIsSaved()
            } catch {
                NetworkManager.shared.logger.error("Error in ProductDetailsViewModel.getPost: \(error.localizedDescription)")
            }
        }
    }

    func setPost(post: Post) {
        item = post
        images = post.images.compactMap { URL(string: $0) }

        Task {
            await calculateMaxImgRatio()
        }

        getIsSaved()
        getSimilarPostsNaive(post: post)
    }

    // Replace once backend endpoint is fix. Currently, making this call blocks all other incoming requests to our backend :(
    func getSimilarPosts(id: String) {
        Task {
            isLoadingImages = true
            defer { isLoadingImages = false }

            do {
                let postsResponse = try await NetworkManager.shared.getSimilarPostsByID(id: id)
                if postsResponse.posts.count >= 4 {
                    similarPosts = Array(postsResponse.posts.prefix(4))
                } else {
                    similarPosts = postsResponse.posts
                }
            } catch {
                NetworkManager.shared.logger.error("Errror in ProductDetailsViewModel.getSimilarPosts: \(error.localizedDescription)")
            }
        }
    }

    func getSimilarPostsNaive(post: Post) {
        Task {
            do {
                let postsResponse = try await NetworkManager.shared.getFilteredPosts(by: post.category ?? "")
                var otherPosts = postsResponse.posts
                otherPosts.removeAll { $0.id == post.id }

                if otherPosts.count >= 4 {
                    similarPosts = Array(otherPosts.prefix(4))
                } else {
                    similarPosts = otherPosts
                }

                isLoadingImages = false
            } catch {
                NetworkManager.shared.logger.error("Errror in ProductDetailsViewModel.getSimilarPostsNaive: \(error.localizedDescription)")
                isLoadingImages = false
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
        if let userId = GoogleAuthManager.shared.user?.firebaseUid,
           let itemUserId = item?.user?.firebaseUid {
            return userId == itemUserId
        }

        return false
    }

    func clear() {
        isSaved = false
        maxDrag = UIScreen.height / 2
        currentPage = 0
        images = []
        maxImgRatio = 1.0
        item = nil
        similarPosts = []
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
    
    // MARK: I DONT KNOW WHAT THIS DOES - Charles
    
//    func createNewNotif() {
//        print(UserSessionManager.shared.userID)
//        Task {
//            do {
//                guard let product = item else {
//                    NetworkManager.shared.logger.error("Error: Product details not available.")
//                    return
//                }
//
//                guard let sellerID = product.user?.id else {
//                    NetworkManager.shared.logger.error("Error: Seller ID not found.")
//                    return
//                }
//
//                let productName = product.title
//
////                let notification = Notification(
////                   // userID: sellerID,
////                    //name: "\(UserSessionManager.shared.userID ?? "Someone") has bookmarked \(productName)"
////                    // body: "Your item '\(productName)' was bookmarked!"
////                    
////                   // data: NotificationData(type: "bookmarks", messageId: UUID().uuidString)
////                )
//
//                try await NetworkManager.shared.createNotif(notifBody: notification)
//                NetworkManager.shared.logger.info("Notification sent successfully!")
//
//            } catch let error as ErrorResponse {
//                // Specific error from app
//                NetworkManager.shared.logger.error("API Error \(error.localizedDescription)")
//            } catch {
//                // General error
//                NetworkManager.shared.logger.error("Unexpected error \(error.localizedDescription)")
//            }
//        }
//    }


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
