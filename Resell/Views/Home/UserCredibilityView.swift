//
//  UserCredibilityView.swift
//  Resell
//
//  Created by Charles Liggins on 10/11/25.
//

// MARK: This isn't being used currently...

// MARK: This applies when viewing external profiles, but I think a lot of things can be ported to the current user viewing their own profile, such as the follower count...

import SwiftUI

struct UserCredibilityView: View {
    @EnvironmentObject var router: Router

    var body: some View {
        VStack{
            headerView
            usernameView
            userAnalyticsView
            following
        }
    }
    
    var headerView: some View {
        VStack{
            HStack{
                Button {
                    router.pop()
                } label: {
                    Image("chevron.left")
                        .resizable()
                        .frame(width: 36, height: 24)
                        .foregroundStyle(.black)
                }
                
                Spacer()
                
                Text("@xhether.resell")
                    .font(Constants.Fonts.h3)
                
                Spacer()
                
                Image(systemName: "ellipsis")
                    .resizable()
                    .frame(width: 24, height: 6)
                    .foregroundStyle(Constants.Colors.black)
                    .padding(.trailing, 16)
                
            }
            
            Divider()
        }
        .padding(.bottom, 25)
    }
    
    var usernameView: some View {
        VStack{
            HStack(spacing: 16){
                // pfp view
                ZStack {
                    Image("pfp")
                        .resizable()
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                    
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .background(Circle().fill(.gray))
                        .frame(width: 21, height: 21)
                        .offset(x:22, y:22)
                }
                
                VStack(spacing: 16){
                    Text("Charles Liggins")
                        .font(Constants.Fonts.h2)
                    
                    HStack{
                        ForEach(0..<5) { _ in
                            // if we could get away from using images here, it might be faster/better...
                            Image(systemName: "star.fill")
                                .resizable()
                                .foregroundStyle(.gray)
                                .frame(width: 12, height: 12)
                        }
                        Text("(0)")
                            .underline()
                    }
                    .padding(.trailing, 32)
                }
            }
            .padding(.trailing, 92)
            .padding(.bottom, 24)
            
            
            Text("I wish I had something to say but I wish I had Kapital Jeans even more...")
                .font(Constants.Fonts.body2)
                .frame(width: 364)
                
        }
        .padding(.bottom, 24)
    }
    
    var userAnalyticsView: some View {
        HStack{
            Spacer()
            (Text("0").fontWeight(.medium) + Text(" sold"))
                .font(Constants.Fonts.body2)
            Spacer()
            Divider()
                .frame(height: 14)
            Spacer()
            (Text("0").fontWeight(.medium) + Text(" followers"))
                .font(Constants.Fonts.body2)
            Spacer()
            Divider()
                .frame(height: 14)
            Spacer()
            (Text("0").fontWeight(.medium) + Text(" following"))
                .font(Constants.Fonts.body2)
            Spacer()
        }
        .padding(.bottom, 24)
    }
    
    var following: some View {
        HStack{
            ZStack{
                RoundedRectangle(cornerRadius: 90)
                    .frame(width: 304, height: 39)
                    .foregroundStyle(Constants.Colors.resellPurple)
                HStack{
                    Image("follow-button")
                        .resizable()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(Color.white)

                    Text("Follow")
                        .fontWeight(.medium)
                        .font(Constants.Fonts.body2)
                        .foregroundStyle(Color.white)
                    
                   
                }
            }
            ZStack{
                Circle()
                    .stroke(Constants.Colors.resellPurple, lineWidth: 1)
                    .frame(width: 39, height: 39)
                
                Image(systemName: "envelope")
                    .resizable()
                    .foregroundStyle(Constants.Colors.resellPurple)
                    .frame(width: 20, height: 15)
                
            }
        }
    }
    
    var reviews: some View {
        Text("Reviews go here...")
    }
    
    var listings: some View {
        Text("Listings go here...")
    }
    // MARK: Idk if theres a convention for this app..
    var storefront_review_tab: some View {
        Text("Tab")
    }
    
}

#Preview {
    UserCredibilityView()
}
