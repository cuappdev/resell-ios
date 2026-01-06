//
//  FollowListView.swift
//  Resell
//
//  Created on 1/2/26.
//

import Kingfisher
import SwiftUI

struct FollowListView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var router: Router
    @State private var selectedTab: FollowListType
    @State private var followers: [User] = []
    @State private var following: [User] = []
    @State private var followingStatus: [String: Bool] = [:]
    @State private var isLoading: Bool = false
    
    let userID: String
    let username: String
    let initialTab: FollowListType
    
    init(userID: String, username: String, initialTab: FollowListType) {
        self.userID = userID
        self.username = username
        self.initialTab = initialTab
        self._selectedTab = State(initialValue: initialTab)
    }
    
    // MARK: - UI
    
    var body: some View {
        VStack(spacing: 0) {
            customToolbar
            
            tabBar
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    if isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else {
                        ForEach(selectedTab == .followers ? followers : following, id: \.firebaseUid) { user in
                            userRow(user: user)
                        }
                    }
                }
            }
            
        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Constants.Colors.white)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            loadData()
        }
    }
    
    private var customToolbar: some View {
        HStack {
            Button {
                router.pop()
            } label: {
                Image(systemName: "chevron.left")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                    .foregroundStyle(Constants.Colors.black)
            }
            .frame(width: 24, alignment: .leading)
            
            Spacer()
            
            Text("@\(username)")
                .font(Constants.Fonts.h3)
                .foregroundStyle(Constants.Colors.black)
            
            Spacer()
            
            Color.clear
                .frame(width: 24)
        }
        .frame(height: 44)
        .padding(.horizontal, 24)
        .background(Constants.Colors.white)
    }
    
    private var tabBar: some View {
        HStack {
            Button {
                withAnimation {
                    selectedTab = .followers
                }
            } label: {
                Text("\(followers.count) Followers")
                    .font(Constants.Fonts.title1)
                    .foregroundColor(selectedTab == .followers ? Constants.Colors.black : Constants.Colors.inactiveGray)
            }
            
            Spacer()
            
            Button {
                withAnimation {
                    selectedTab = .following
                }
            } label: {
                Text("\(following.count) Following")
                    .font(Constants.Fonts.title1)
                    .foregroundColor(selectedTab == .following ? Constants.Colors.black : Constants.Colors.inactiveGray)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 48)
        .background(Constants.Colors.white)
        .overlay(alignment: .bottom) {
            GeometryReader { geo in
                Rectangle()
                    .fill(Constants.Colors.resellPurple)
                    .frame(width: geo.size.width / 2, height: 2)
                    .offset(x: selectedTab == .followers ? 0 : geo.size.width / 2)
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)
            }
            .frame(height: 2)
        }
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
    
    private func userRow(user: User) -> some View {
        HStack(spacing: 12) {
            Button {
                router.push(.profile(user.firebaseUid))
            } label: {
                HStack(spacing: 12) {
                    KFImage(user.photoUrl)
                        .cacheOriginalImage()
                        .placeholder {
                            Circle()
                                .fill(Constants.Colors.wash)
                                .frame(width: 50, height: 50)
                        }
                        .resizable()
                        .frame(width: 50, height: 50)
                        .clipShape(.circle)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.givenName)
                            .font(Constants.Fonts.title1)
                            .foregroundColor(Constants.Colors.black)
                        
                        Text("@\(user.username)")
                            .font(Constants.Fonts.body2)
                            .foregroundColor(Constants.Colors.secondaryGray)
                    }
                }
            }
            
            Spacer()
            
            if user.firebaseUid != GoogleAuthManager.shared.user?.firebaseUid {
                followButton(for: user)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
    
    private func followButton(for user: User) -> some View {
        let isFollowing = followingStatus[user.firebaseUid] ?? false
        
        return Button {
            Task {
                await toggleFollow(for: user)
            }
        } label: {
            Text(isFollowing ? "Following" : "Follow")
                .font(Constants.Fonts.title3)
                .foregroundColor(isFollowing ? Constants.Colors.resellPurple : .white)
                .frame(width: 100, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isFollowing ? Constants.Colors.white : Constants.Colors.resellPurple)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Constants.Colors.resellPurple, lineWidth: isFollowing ? 1.5 : 0)
                )
        }
    }
    
    // MARK: - Functions
    
    private func loadData() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                async let fetchedFollowers = NetworkManager.shared.getFollowers(id: userID).users
                async let fetchedFollowing = NetworkManager.shared.getFollowing(id: userID).users
                
                followers = try await fetchedFollowers
                following = try await fetchedFollowing
                
                // Check which users the current user is following
                if let currentUserId = GoogleAuthManager.shared.user?.firebaseUid {
                    let currentUserFollowing = try await NetworkManager.shared.getFollowing(id: currentUserId).users
                    let followingIds = Set(currentUserFollowing.map { $0.firebaseUid })
                    
                    for user in followers + following {
                        followingStatus[user.firebaseUid] = followingIds.contains(user.firebaseUid)
                    }
                }
            } catch {
                NetworkManager.shared.logger.error("Error loading follow data: \(error)")
            }
        }
    }
    
    private func toggleFollow(for user: User) async {
        let isCurrentlyFollowing = followingStatus[user.firebaseUid] ?? false
        
        do {
            if isCurrentlyFollowing {
                let unfollow = UnfollowUserBody(userId: user.firebaseUid)
                _ = try await NetworkManager.shared.unfollowUser(unfollow: unfollow)
                followingStatus[user.firebaseUid] = false
            } else {
                let follow = FollowUserBody(userId: user.firebaseUid)
                _ = try await NetworkManager.shared.followUser(follow: follow)
                followingStatus[user.firebaseUid] = true
            }
        } catch {
            NetworkManager.shared.logger.error("Error toggling follow: \(error)")
        }
    }
}
