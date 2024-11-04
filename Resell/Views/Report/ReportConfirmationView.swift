//
//  ReportConfirmationView.swift
//  Resell
//
//  Created by Richie Sun on 10/19/24.
//

import SwiftUI

struct ReportConfirmationView: View {

    // MARK: - Properties
    
    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: ReportViewModel

    // MARK: - UI

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image("checkMark")
                .resizable()
                .frame(width: 89, height: 89)

            Text("Thank you for reporting this \(viewModel.reportType)")
                .font(Constants.Fonts.h2)
                .foregroundStyle(Constants.Colors.black)
                .multilineTextAlignment(.center)
                .padding(.top, 32)

            Text("Your report is valued in keeping Resell a safe community. We will be carefully reviewing the \(viewModel.reportType) and taking any necessary action. ")
                .font(.custom("Rubik-Regular", size: 16))
                .foregroundStyle(Constants.Colors.secondaryGray)
                .multilineTextAlignment(.center)

            Spacer()

            Text("Block Account?")
                .font(Constants.Fonts.h3)
                .foregroundStyle(Constants.Colors.black)
                .multilineTextAlignment(.center)

            Button {
                withAnimation {
                    viewModel.didShowPopup = true
                }
            } label: {
                Text("Block \(viewModel.username)")
                    .font(Constants.Fonts.body1)
                    .foregroundStyle(Constants.Colors.errorRed)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Constants.Colors.errorRed, lineWidth: 1.5)
                    }
            }
            .padding(.bottom, Constants.Spacing.horizontalPadding)

        }
        .background(Constants.Colors.white)
        .padding(.horizontal, 55)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Report \(viewModel.reportType)")
                    .font(Constants.Fonts.h3)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.popToRoot()
                    viewModel.clear()
                } label: {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .tint(Constants.Colors.black)
                }
            }
        }
        .popupModal(isPresented: $viewModel.didShowPopup) {
            VStack(spacing: 16) {
                Text("Blocker User")
                    .font(Constants.Fonts.h3)
                    .foregroundStyle(Constants.Colors.black)

                Text("Are you sure you’d like to block this user?")
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.black)
                    .multilineTextAlignment(.center)

                HStack(alignment: .center) {
                    Button {
                        withAnimation {
                            viewModel.didShowPopup = false
                        }
                    } label: {
                        Text("Cancel")
                            .font(Constants.Fonts.title1)
                            .foregroundStyle(Constants.Colors.resellPurple)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 40)
                    }

                    Button {
                        // TODO: Backend Call Block User
                        router.popToRoot()
                        viewModel.clear()
                    } label: {
                        Text("Block")
                            .font(Constants.Fonts.body1)
                            .foregroundStyle(Constants.Colors.errorRed)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 40)
                            .overlay {
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Constants.Colors.errorRed, lineWidth: 1.5)
                            }
                    }
                }
            }
            .padding(Constants.Spacing.horizontalPadding)
            .frame(width: 325)
        }
    }
}
