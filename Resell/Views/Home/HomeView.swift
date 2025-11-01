//
//  HomeView.swift
//  Resell
//
//  Created by Richie Sun on 9/11/24.
//

import Kingfisher
import SwiftUI

struct HomeView: View {

    @EnvironmentObject private var mainViewModel: MainViewModel
    @EnvironmentObject var router: Router
    @StateObject private var viewModel = HomeViewModel.shared

    var body: some View {
        NavigationStack(path: $router.path) {
            VStack(spacing: 0) {
                headerView

                filtersView

                ProductsGalleryView(items: viewModel.filteredItems)
            }
            .background(Constants.Colors.white)
            .overlay(alignment: .bottomTrailing) {
                ExpandableAddButton()
                    .padding(.bottom, 40)
            }
            .onAppear {
                Task {
//                    do {
//                        let authToken = try await GoogleAuthManager.shared.getOAuthToken()
//                        try await FirebaseNotificationService.shared.sendNotification(title: "PENIS", body: "I WANT YOUR PENIS", recipientToken: "eS3G22mJQZaQPqAdjbJ5Bp:APA91bGnkNJFNKDWSVxDGTF5eJSR4Lem9uvr1MgZ3jVAluPRAFei1nlYkM1EtS4Z2W55zv74CBp1yUpQwnKl6TOY1DScsNRLRAoFSYMD22IcGnOvMPmmhKA", navigationId: "", authToken: authToken ?? "")
//                    } catch {
//                        print(error)
//                    }

                }
                viewModel.getAllPosts()
                viewModel.getBlockedUsers()

                withAnimation {
                    mainViewModel.hidesTabBar = false
                }
            }
            .refreshable {
                viewModel.getAllPosts()
            }
            .navigationBarBackButtonHidden()
        }
    }

    private var headerView: some View {
        HStack {
            Text("resell")
                .font(Constants.Fonts.resellHeader)
                .foregroundStyle(Constants.Colors.resellGradient)

            Spacer()

            Button(action: {
                router.push(.search(nil))
            }, label: {
                Icon(image: "search")
            })
        }
        .padding(.horizontal, Constants.Spacing.horizontalPadding)
    }

    private var filtersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Constants.filters, id: \.id) { filter in
                    FilterButton(filter: filter, isSelected: viewModel.selectedFilter == filter.title) {
                        viewModel.selectedFilter = filter.title
                    }
                }
            }
            .padding(.leading, Constants.Spacing.horizontalPadding)
            .padding(.vertical, 1)
        }
    }
}
