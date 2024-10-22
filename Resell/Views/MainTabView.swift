//
//  MainTabView.swift
//  Resell
//
//  Created by Richie Sun on 10/9/24.
//

import SwiftUI

struct MainTabView: View {

    // MARK: - Properties

    @Binding var isHidden: Bool
    @Binding var selection: Int
    @EnvironmentObject var router: Router

    // MARK: - ViewModels

    @StateObject private var newListingViewModel = NewListingViewModel()
    @StateObject private var reportViewModel = ReportViewModel()

    // MARK: - UI

    var body: some View {
        NavigationStack(path: $router.path) {
            ZStack(alignment: .bottom) {
                ZStack() {
                    if selection == 0 {
                        HomeView()
                    } else if selection == 1 {
                        SavedView()
                    } else if selection == 2 {
                        ChatsView()
                    } else if selection == 3 {
                        ProfileView()
                    }
                }
                .navigationDestination(for: Router.Route.self) { route in
                    switch route {
                    case .newListingDetails:
                        NewListingDetailsView()
                            .environmentObject(newListingViewModel)
                    case .newListingImages:
                        NewListingImagesView()
                            .environmentObject(newListingViewModel)
                    case .newRequest:
                        NewRequestView()
                    case .productDetails(let itemID):
                        ProductDetailsView(userIsSeller: false, item: Item.defaultItem)
                    case .reportConfirmation:
                        ReportConfirmationView()
                            .environmentObject(reportViewModel)
                    case .reportDetails:
                        ReportDetailsView()
                            .environmentObject(reportViewModel)
                    case .reportOptions:
                        ReportOptionsView()
                            .environmentObject(reportViewModel)
                    default:
                        EmptyView()
                    }
                }


                if !isHidden {
                    HStack {
                        ForEach(0..<4, id: \.self) { index in
                            TabViewIcon(selectionIndex: $selection, itemIndex: index)
                                .frame(width: 28, height: 28)

                            if index != 3 {
                                Spacer()
                            }
                        }
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .padding(.horizontal, 40)
                    .padding(.top, 16)
                    .padding(.bottom, 36)
                    .background(Constants.Colors.white)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(radius: 4)
                    .offset(y: 34)
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: isHidden)
                }
            }
        }
    }
}
