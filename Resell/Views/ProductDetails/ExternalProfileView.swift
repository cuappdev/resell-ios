//
//  ExternalProfileView.swift
//  Resell
//
//  Created by Richie Sun on 11/16/24.
//

import Kingfisher
import SwiftUI

struct ExternalProfileView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    @StateObject private var viewModel = ProfileViewModel()
    @State var listingViewIsPresented: Bool = true
    @State private var didShowUnfollowPopup: Bool = false

    var userID: String

    // MARK: - UI
    // TODO: It should be impossible for the externalUser to be inactive/null

    var body: some View {
        VStack(spacing: 0) {
            customToolbar
            ScrollView {
                
                
                ZStack {
                    VStack(alignment: .leading) {
                        profileView
                            .padding(.top, 25)
                            .padding(.leading, 26)
                        
                        profileTabBar
                        
                        if listingViewIsPresented {
                            ScrollView {
                                ProductsGalleryView(items: viewModel.externalUserPosts)
                                    .loadingView(isLoading: viewModel.isLoadingExternalUser)
                                    .padding(.top, 16)
                            }
                            .background(Constants.Colors.white)
                        } else {
                            ScrollView {
                                ReviewSection(reviews: viewModel.externalUserReviews)
                                    .loadingView(isLoading: viewModel.isLoadingExternalUser)
                            }
                            .background(Constants.Colors.white)
                        }
                    }
                    .background(Constants.Colors.white)
                    .onAppear {
                        viewModel.loadExternalUser(id: userID)
                    }
                    
                    if viewModel.sellerIsBlocked {
                        ZStack {
                            Constants.Colors.black
                                .opacity(0.75)
                                .ignoresSafeArea()
                            
                            Text("This profile is blocked")
                                .font(Constants.Fonts.title1)
                                .foregroundStyle(Constants.Colors.white)
                        }
                        .animation(.easeInOut, value: viewModel.sellerIsBlocked)
                    }
                    
                    if viewModel.didShowOptionsMenu {
                        OptionsMenuView(showMenu: $viewModel.didShowOptionsMenu, didShowBlockView: $viewModel.didShowBlockView, options: {
                            var options: [Option] = [
                                .report(type: "User", id: userID),
                            ]
                            if viewModel.sellerIsBlocked {
                                options.append(.unblock)
                            } else {
                                options.append(.block)
                            }
                            return options
                        }())
                        .zIndex(1)
                    }
                }
                .popupModal(isPresented: $viewModel.didShowBlockView) {
                    popupModalContent
                }
                .sheet(isPresented: $didShowUnfollowPopup) {
                    unfollowSheetContent
                        .presentationDetents([.height(375)])
                        .presentationDragIndicator(.visible)
                }
                // MARK: We should not be able to click into our own posts...
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private var profileView: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                profileImageView
                
                VStack (alignment: .leading, spacing: 10.5) {
                    Text(viewModel.externalUser?.givenName ?? "")
                        .font(Constants.Fonts.h2)
                        .foregroundStyle(.black)
                    
                    HStack {
                        StarRatingView(rating: viewModel.averageStarRating)
                        
                        Text("(\(viewModel.reviewCount))")
                            .font(Constants.Fonts.body2)
                            .underline()
                            .foregroundStyle(Constants.Colors.inactiveGray)
                    }
                }
            }
            
            // bio
            Text(viewModel.displayBio)
                .font(Constants.Fonts.body2)
                .foregroundStyle(.black)
            
            // metrics bar
            HStack {
                Text("\(viewModel.soldCount)")
                .font(Constants.Fonts.body2)
                .fontWeight(.medium)
                .foregroundColor(.black)
                + Text(" sold")
                .font(Constants.Fonts.body2)
                .foregroundColor(.gray)
                
                Divider()
                    .frame(height: 14)
                    .padding(.horizontal, 28.75)

                Button {
                    router.push(.followList(
                        userID: userID,
                        username: viewModel.externalUser?.username ?? "",
                        initialTab: .followers
                    ))
                } label: {
                    Text("\(viewModel.followerCount)")
                    .font(Constants.Fonts.body2)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    + Text(" followers")
                    .font(Constants.Fonts.body2)
                    .foregroundColor(.gray)
                }
                
                Divider()
                    .frame(height: 14)
                    .padding(.horizontal, 28.75)
                
                Button {
                    router.push(.followList(
                        userID: userID,
                        username: viewModel.externalUser?.username ?? "",
                        initialTab: .following
                    ))
                } label: {
                    Text("\(viewModel.followingCount)")
                    .font(Constants.Fonts.body2)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    + Text(" following")
                    .font(Constants.Fonts.body2)
                    .foregroundColor(.gray)
                }
            }
            
            HStack {
                Button {
                    if viewModel.isFollowing {
                        withAnimation {
                            didShowUnfollowPopup = true
                        }
                    } else {
                        Task {
                            do {
                                try await viewModel.followUser(id: userID)
                            } catch {
                                NetworkManager.shared.logger.error("Error following user: \(error)")
                            }
                        }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 90.79)
                            .foregroundStyle(viewModel.isFollowing ? Constants.Colors.white : Constants.Colors.resellPurple)
                            .overlay(
                                RoundedRectangle(cornerRadius: 90.79)
                                    .stroke(Constants.Colors.resellPurple, lineWidth: viewModel.isFollowing ? 1.5 : 0)
                            )
                            .frame(width: 366, height: 38.79)
                        
                        if viewModel.isFollowLoading {
                            ProgressView()
                                .tint(viewModel.isFollowing ? Constants.Colors.resellPurple : .white)
                        } else {
                            HStack {
                                Image(viewModel.isFollowing ? "following" : "following")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 13, height: 13)
                                
                                Text(viewModel.isFollowing ? "Following" : "Follow")
                                    .font(Constants.Fonts.title3)
                            }
                            .foregroundColor(viewModel.isFollowing ? Constants.Colors.resellPurple : .white)
                        }
                    }
                }
                .disabled(viewModel.isFollowLoading)
            }
        }
        .padding(.trailing, 26)

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
            
            Text("@\(viewModel.externalUser?.username ?? "username")")
                .font(Constants.Fonts.h3)
                .foregroundStyle(Constants.Colors.black)
            
            Spacer()
            
            Button {
                withAnimation {
                    viewModel.didShowOptionsMenu.toggle()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .resizable()
                    .frame(width: 24, height: 6)
                    .foregroundStyle(viewModel.sellerIsBlocked ? Constants.Colors.white : Constants.Colors.black)
            }
            .frame(width: 24, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 26)
        .padding(.top, 10)
        .overlay(alignment: .bottom) {
            Divider()
        }
        .background(Constants.Colors.white)
    }
    
    private var profileTabBar: some View {
        HStack {
            // Listings tab
            Button {
                withAnimation {
                    listingViewIsPresented = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image("listing")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    
                    Text("(\(viewModel.externalUserPosts.count))")
                        .font(Constants.Fonts.body2)
                }
                .foregroundColor(listingViewIsPresented ? Constants.Colors.resellPurple : Constants.Colors.inactiveGray)
            }
            
            Spacer()
            
            // Reviews tab
            Button {
                withAnimation {
                    listingViewIsPresented = false
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    
                    Text(String(format: "%.1f", viewModel.averageStarRating))
                        .font(Constants.Fonts.body2)
                        .fontWeight(.medium)
                    + Text(" (\(viewModel.reviewCount))")
                        .font(Constants.Fonts.body2)
                }
                .foregroundColor(listingViewIsPresented ? Constants.Colors.inactiveGray : Constants.Colors.resellPurple)
            }
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 16)
        .overlay(alignment: .bottom) {
            GeometryReader { geo in
                Rectangle()
                    .fill(Constants.Colors.resellPurple)
                    .frame(width: geo.size.width / 2, height: 2)
                    .offset(x: listingViewIsPresented ? 0 : geo.size.width / 2)
                    .animation(.easeInOut(duration: 0.2), value: listingViewIsPresented)
            }
            .frame(height: 2)
        }
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var profileImageView: some View {
        KFImage(viewModel.externalUser?.photoUrl)
            .cacheOriginalImage()
            .placeholder {
                ShimmerView()
                    .frame(width: 67, height: 67)
            }
            .resizable()
            .frame(width: 67, height: 67)
            .clipShape(.circle)
    }

    private var popupModalContent: some View {
        VStack(spacing: 24) {
            Text("Block User")
                .font(Constants.Fonts.h3)
                .foregroundStyle(Constants.Colors.black)

            Text("Are you sure you’d like to \(viewModel.sellerIsBlocked ? "un" : "")block this user?")
                .font(Constants.Fonts.body2)
                .foregroundStyle(Constants.Colors.black)
                .multilineTextAlignment(.center)
                .frame(width: 275)

            PurpleButton(isLoading: viewModel.isLoading,text: viewModel.sellerIsBlocked ? "Unblock" : "Block", horizontalPadding: 100) {
                if viewModel.sellerIsBlocked {
                    Task {
                        try await viewModel.unblockUser(id: userID)
                    }
                } else {
                    Task{
                        try await viewModel.blockUser(id: userID)
                    }
                }
            }

            Button{
                withAnimation {
                    viewModel.didShowBlockView = false
                }
            } label: {
                Text("Cancel")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.secondaryGray)
            }
        }
        .padding(Constants.Spacing.horizontalPadding)
    }

    private var unfollowSheetContent: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack(alignment: .bottomTrailing) {
                KFImage(viewModel.externalUser?.photoUrl)
                    .cacheOriginalImage()
                    .placeholder {
                        ShimmerView()
                            .frame(width: 100, height: 100)
                    }
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(.circle)
                
                ZStack {
                    Circle()
                        .fill(Constants.Colors.resellPurple)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "minus")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                }
                .offset(x: 4, y: 4)
            }
            .padding(.top, 16)
            
            Text("Unfollow @\(viewModel.externalUser?.username ?? "user")")
                .font(Constants.Fonts.h3)
                .foregroundStyle(Constants.Colors.black)
            
            VStack(spacing: 16) {
                Button {
                    Task {
                        do {
                            try await viewModel.unfollowUser(id: userID)
                            didShowUnfollowPopup = false
                        } catch {
                            NetworkManager.shared.logger.error("Error unfollowing user: \(error)")
                        }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 36)
                            .foregroundStyle(Constants.Colors.resellPurple)
                            .frame(height: 56)
                        
                        if viewModel.isFollowLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Yes, Unfollow")
                                .font(Constants.Fonts.title1)
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(viewModel.isFollowLoading)
                
                Button {
                    didShowUnfollowPopup = false
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .foregroundStyle(Constants.Colors.wash)
                            .frame(height: 56)
                        
                        Text("No, Keep Following")
                            .font(Constants.Fonts.title1)
                            .foregroundColor(Constants.Colors.black)
                    }
                }
            }
            .padding(.horizontal, 40)
            
        }
        .frame(maxWidth: .infinity)
        .background(Constants.Colors.white)
    }

}
