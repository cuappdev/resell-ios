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
    @Published var maxDrag: CGFloat = UIScreen.main.bounds.height / 2
    @Published var maxImgRatio: CGFloat = 1.0
    @Published var item: Post?
    @Published var similarPosts: [Post] = []

    private var refetchTask: Task<Void, Never>?
    private var maxImgRatioTask: Task<Void, Never>?

    // MARK: - Functions


    func isMyPost() -> Bool {
        if let userID = GoogleAuthManager.shared.user?.firebaseUid {
            if userID == item?.user?.firebaseUid {
                return true
            }
        }

        return false
    }

    func setPost(post: Post) {
        item = post
        images = post.images.compactMap { URL(string: $0) }

        maxImgRatioTask?.cancel()
        maxImgRatioTask = Task { [weak self] in
            await self?.calculateMaxImgRatio()
        }

        getIsSaved()
        getSimilarPosts(id: post.id)

        // Always refetch the full post in the background so the view shows
        // current data (e.g. user info missing from the saved-posts endpoint,
        // updated sold status, price, description, images, etc.). The local
        // copy is used for an immediate optimistic render above.
        refetchTask?.cancel()
        refetchTask = Task { [weak self] in
            guard let self else { return }
            do {
                let postResponse = try await NetworkManager.shared.getPostByID(id: post.id)
                try Task.checkCancellation()
                guard let fullPost = postResponse.post, fullPost.id == self.item?.id else { return }

                self.item = fullPost
                let newImageURLs = fullPost.images.compactMap { URL(string: $0) }
                if newImageURLs != self.images {
                    self.images = newImageURLs
                    self.maxImgRatioTask?.cancel()
                    self.maxImgRatioTask = Task { [weak self] in
                        await self?.calculateMaxImgRatio()
                    }
                }
            } catch is CancellationError {
                return
            } catch {
                NetworkManager.shared.logger.error("Error in ProductDetailsViewModel.setPost (refetch): \(error)")
            }
        }
    }

    // Replace once backend endpoint is fix. Currently, making this call blocks all other incoming requests to our backend :(
    func getSimilarPosts(id: String) {
        Task {
            isLoadingImages = true
            defer { isLoadingImages = false }

            do {
                let postsResponse = try await NetworkManager.shared.getSimilarPostsByID(id: id)
                similarPosts = Array(postsResponse.posts)
                print("# of similar posts: \(similarPosts.count)")
                
            } catch {
                NetworkManager.shared.logger.error("Errror in ProductDetailsViewModel.getSimilarPosts: \(error)")
            }
        }
    }

    func updateItemSaved() async {
        do {
            if let id = item?.id {
                if !isSaved {
                    let _ = try await NetworkManager.shared.unsavePostByID(id: id)
                } else {
                    let _ = try await NetworkManager.shared.savePostByID(id: id)
                }
            }
        } catch {
            NetworkManager.shared.logger.error("Error in ProductDetailsViewModel:.updateItemSaved \(error)")
        }
    }

    func getIsSaved() {
        Task {
            do {
                if let id = item?.id {
                    isSaved = try await NetworkManager.shared.postIsSaved(id: id).isSaved
                }
            } catch {
                NetworkManager.shared.logger.error("Error in ProductDetailsViewModel.getIsSaved: \(error)")
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
                NetworkManager.shared.logger.error("Error in ProductDetailsViewModel.archivePost: \(error)")
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
                NetworkManager.shared.logger.error("Error in ProductDetailsViewModel.deletePost: \(error)")
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
        refetchTask?.cancel()
        refetchTask = nil
        maxImgRatioTask?.cancel()
        maxImgRatioTask = nil

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
    
   


    private func calculateMaxImgRatio() async {
        let urls = images
        var maxRatio = 0.0
        for imageUrl in urls {
            if Task.isCancelled { return }
            guard let data = try? await URLSession.shared.data(from: imageUrl).0,
                  let image = UIImage(data: data) else { continue }

            let aspectRatio = image.aspectRatio

            maxRatio = max(maxRatio, aspectRatio)
        }

        if Task.isCancelled { return }
        withAnimation {
            maxImgRatio = maxRatio
        }
    }
}
