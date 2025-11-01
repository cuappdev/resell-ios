//
//  Constants.swift
//  Resell
//
//  Created by Richie Sun on 9/9/24.
//

import SwiftUI

struct Constants {

    /// Colors used in Resell's design system
    enum Colors {

        // Colors
        static let black = Color(red: 0/255, green: 0/255, blue: 0/255)
        static let errorRed = Color(red: 242/255, green: 0/255, blue: 0/255)
        static let inactiveGray = Color(red: 190/255, green: 190/255, blue: 190/255)
        static let purpleWash = Color(red: 250/255, green: 247/255, blue: 255/255)
        static let resellPurple = Color(red: 158/255, green: 112/255, blue: 246/255)
        static let secondaryGray = Color(red: 77/255, green: 77/255, blue: 77/255)
        static let stroke = Color(red: 214/255, green: 214/255, blue: 214/255)
        static let tint = Color(red: 0/255, green: 0/255, blue: 0/255, opacity: 20/100)
        static let wash = Color(red: 244/255, green: 244/255, blue: 244/255)
        static let white = Color(red: 255/255, green: 255/255, blue: 255/255)
        
        // filter colors
        static let filterGray = Color(red: 214/255, green: 214/255, blue: 214/255)
        static let filterPink = Color(red: 202/255, green: 149/255, blue: 163/255)
        static let filterGreen = Color(red: 49/255, green: 96/255, blue: 84/255)
        static let filterLightGreen = Color(red: 164/255, green: 183/255, blue: 171/255)
        static let filterYellow = Color(red: 227/255, green: 181/255, blue: 112/255)
        static let filterBlue = Color(red: 115/255, green: 162/255, blue: 171/255)
        

        // Gradients
        static let resellGradient = LinearGradient(stops: [
            .init(color: Color(red: 173/255, green: 104/255, blue: 227/255), location: 0.0),
            .init(color: Color(red: 222/255, green: 108/255, blue: 211/255), location: 0.5),
            .init(color: Color(red: 223/255, green: 152/255, blue: 86/255), location: 1.0)
        ], startPoint: .leading, endPoint: .trailing)
        static let resellBlurGradient1 = LinearGradient(stops: [
            .init(color: Color(red: 255/255, green: 19/255, blue: 231/255), location: 0.0),
            .init(color: Color(red: 255/255, green: 122/255, blue: 0/255), location: 1.0),
        ], startPoint: .bottom, endPoint: .top)
        static let resellBlurGradient2 = LinearGradient(stops: [
            .init(color: Color(red: 173/255, green: 104/255, blue: 227/255), location: 0.0),
            .init(color: Color(red: 223/255, green: 152/255, blue: 86/255), location: 1.0)
        ], startPoint: .leading, endPoint: .trailing)

    }

    /// Typography used in Resell's design system
    enum Fonts {
        // Resell logo
        static let resellLogo = Font.custom("ReemKufi-Regular", size: 48)
        static let resellHeader = Font.custom("ReemKufi-Regular", size: 32)

        // Headers
        static let h1 = Font.custom("Rubik-Medium", size: 32)
        static let h2 = Font.custom("Rubik-Medium", size: 22)
        static let h3 = Font.custom("Rubik-Medium", size: 20)

        // Body
        static let body1 = Font.custom("Rubik-Regular", size: 18)
        static let body2 = Font.custom("Rubik-Regular", size: 16)

        // Titles
        static let title1 = Font.custom("Rubik-Medium", size: 18)
        static let title2 = Font.custom("Rubik-Medium", size: 16)
        static let title3 = Font.custom("Rubik-Medium", size: 14)
        static let title4 = Font.custom("Rubik-Regular", size: 14)
        static let subtitle1 = Font.custom("Rubik-Regular", size: 12)
    }

    /// Spacing amounts used in Resell's design system
    enum Spacing {
        static let spacing64: CGFloat = 64.0
        static let spacing36: CGFloat = 36.0
        static let spacing16: CGFloat = 16.0
        static let spacing12: CGFloat = 12.0
        static let spacing8: CGFloat = 8.0

        static let horizontalPadding: CGFloat = 24.0
    }

    /// Chat  categories used in Resell's design system
    static let chats = [
        FilterCategory(id: 0, title: ChatTab.purchases.rawValue),
        FilterCategory(id: 1, title: ChatTab.offers.rawValue)
    ]

    /// Product filter categories used in Resell's design system
    static let filters = [
        FilterCategory(id: 0, title: "Recent"),
        FilterCategory(id: 1, title: "Clothing", color: Constants.Colors.filterPink),
        FilterCategory(id: 2, title: "Books", color: Constants.Colors.filterGreen) ,
        FilterCategory(id: 3, title: "School", color: Constants.Colors.filterLightGreen),
        FilterCategory(id: 4, title: "Electronics", color: Constants.Colors.filterPink),
        FilterCategory(id: 5, title: "Household"),
        FilterCategory(id: 6, title: "Handmade", color: Constants.Colors.filterYellow),
        FilterCategory(id: 7, title: "Sports & Outdoors", color: Constants.Colors.filterBlue),
        FilterCategory(id: 8, title: "Other")
    ]
    
    static let notificationFilters = [
        FilterCategory(id: 0, title: "All"),
        FilterCategory(id: 1, title: "Messages"),
        FilterCategory(id: 2, title: "Requests"),
        FilterCategory(id: 3, title: "Bookmarks"),
        FilterCategory(id: 4, title: "Your Listings")
    ]

    static let chatMessageOptions: [ChatMessageOption] = [
        .negotiate,
        .sendAvailability,
        .venmo,
        .viewAvailability
    ]

    static let dummyItemsData: [Item] = [
        Item(id: UUID(), title: "Justin", image: "justin", price: "100", category: "School"),
        Item(id: UUID(), title: "Justin", image: "justin_long", price: "100", category: "School"),
        Item(id: UUID(), title: "Justin", image: "justin_long", price: "100", category: "School"),
        Item(id: UUID(), title: "Justin", image: "justin", price: "100", category: "School"),
        Item(id: UUID(), title: "Justin", image: "justin_long", price: "100", category: "School"),
        Item(id: UUID(), title: "Justin", image: "justin", price: "100", category: "School"),
        Item(id: UUID(), title: "Justin", image: "justin", price: "100", category: "School"),
        Item(id: UUID(), title: "Justin", image: "justin_long", price: "100", category: "School"),
        Item(id: UUID(), title: "Justin", image: "justin_long", price: "100", category: "School"),
        Item(id: UUID(), title: "Justin", image: "justin", price: "100", category: "School"),
        Item(id: UUID(), title: "Justin", image: "justin_long", price: "100", category: "School"),
        Item(id: UUID(), title: "Justin", image: "justin", price: "100", category: "School"),
    ]
}

struct FilterCategory: Hashable {
    let id: Int
    let title: String
    let color: Color?
    
    init(id: Int, title: String, color: Color? = nil) {
         self.id = id
         self.title = title
         self.color = color
     }
}

enum ChatMessageOption: String {
    case negotiate = "Negotiate"
    case sendAvailability = "Send Availability"
    case venmo = "Pay with Venmo"
    case viewAvailability = "View Availability"
}
