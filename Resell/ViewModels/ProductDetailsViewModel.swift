//
//  ProductDetailsViewModel.swift
//  Resell
//
//  Created by Richie Sun on 10/17/24.
//

import SwiftUI

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
        Task {
            isLoading = true

            do {
                let postResponse = try await NetworkManager.shared.getPostByID(id: id)
                item = postResponse.post
                images = postResponse.post.images

                await calculateMaxImgRatio()
                getIsSaved()

                isLoading = false
            } catch {
                NetworkManager.shared.logger.error("Error in ProductDetailsViewModel.getPost: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }

    func getSimilarPosts(id: String) {
        Task {
            isLoadingImages = true

            do {
                let postsResponse = try await NetworkManager.shared.getSimilarPostsByID(id: id)
                if postsResponse.posts.count >= 4 {
                    similarPosts = Array(postsResponse.posts.prefix(4))
                } else {
                    similarPosts = postsResponse.posts
                }

                isLoadingImages = false
            } catch {
                NetworkManager.shared.logger.error("Errror in ProductDetailsViewModel.getSimilarPosts: \(error.localizedDescription)")
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
        if let userId = UserSessionManager.shared.userID,
           let itemUserId = item?.user?.id {
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
