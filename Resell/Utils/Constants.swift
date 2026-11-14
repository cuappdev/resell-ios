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
        static let lightPurpleWash = Color(red: 247/255, green: 242/255, blue: 255/255)
        static let mediumGray = Color(red: 103/255, green: 103/255, blue: 103/255)
        static let mutedGray = Color(red: 112/255, green: 112/255, blue: 112/255)
        static let purpleWash = Color(red: 250/255, green: 247/255, blue: 255/255)
        static let resellPurple = Color(red: 158/255, green: 112/255, blue: 246/255)
        static let tertiaryGray = Color(red: 45/255, green: 45/255, blue: 45/255)
        static let secondaryGray = Color(red: 77/255, green: 77/255, blue: 77/255)
        static let shadow = Color(red: 0/255, green: 0/255, blue: 0/255, opacity: 25/100)
        static let stroke = Color(red: 214/255, green: 214/255, blue: 214/255)
        static let tint = Color(red: 0/255, green: 0/255, blue: 0/255, opacity: 20/100)
        static let wash = Color(red: 244/255, green: 244/255, blue: 244/255)
        static let white = Color(red: 255/255, green: 255/255, blue: 255/255)
        
        // filter colors
        static let filterGray = Color(red: 214/255, green: 214/255, blue: 214/255)
        static let filterPink = Color(red: 202/255, green: 149/255, blue: 163/255)
        static let filterGreen = Color(red: 49/255, green: 96/255, blue: 84/255)
        static let filterLightGreen = Color(red: 164/255, green: 183/255, blue: 171/255)
        static let filterBlue = Color(red: 115/255, green: 162/255, blue: 171/255)
        
        // Tab bar
        static let tabBarInactive = Color(red: 158/255, green: 158/255, blue: 163/255)
        static let tabBarSelection = Color(red: 121/255, green: 86/255, blue: 61/255, opacity: 16/100)
        static let tabBarShadow = Color(red: 0/255, green: 0/255, blue: 0/255, opacity: 12/100)
        /// Grays the tab bar's glass to Figma's body tone.
        static let tabBarGlassTint = Color(red: 0/255, green: 0/255, blue: 0/255, opacity: 6/100)
        /// Keeps busy content behind the tab bar from showing through its icons.
        static let tabBarGlassBacking = Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 70/100)

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
        static let tabBarActiveGradient = LinearGradient(stops: [
            .init(color: Color(red: 164/255, green: 98/255, blue: 230/255), location: 0.0),
            .init(color: Color(red: 209/255, green: 111/255, blue: 192/255), location: 0.5),
            .init(color: Color(red: 224/255, green: 160/255, blue: 99/255), location: 1.0)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)

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
        static let subtitle2 = Font.custom("Rubik-Medium", size: 12)

        // Tab bar
        static let badge = Font.custom("Roboto-Medium", size: 10)
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

    /// Layout values for the Sell tab
    enum Sell {
        static let maxImages = 8

        static let photoSlotWidth: CGFloat = 231
        static let photoSlotHeight: CGFloat = 294
        static let photoSlotCornerRadius: CGFloat = 15
        static let photoSlotSpacing: CGFloat = 15
        static let photoSlotBorderWidth: CGFloat = 2
        static let photoSlotDash: [CGFloat] = [6, 4]
        static let photoSlotBadgeInset: CGFloat = 16
        /// Half of Figma's blur of 10, since SwiftUI's radius spreads twice as far.
        static let photoShadowRadius: CGFloat = 5
        static let photoShadowY: CGFloat = 2

        static let coverPillHeight: CGFloat = 30
        static let addButtonWidth: CGFloat = 123
        static let addButtonHeight: CGFloat = 30
        static let addPhotoIconSize = CGSize(width: 47.25, height: 41.25)
        static let removeIconSize: CGFloat = 23
        static let removeButtonSize: CGFloat = 32
        static let removeButtonInset: CGFloat = 12

        static let formSpacing: CGFloat = 20
        static let fieldLabelSpacing: CGFloat = 12
        static let fieldHeight: CGFloat = 43
        static let fieldHorizontalPadding: CGFloat = 17
        static let pricePillWidth: CGFloat = 128
        static let pricePillVerticalPadding: CGFloat = 10
        static let rowValueSpacing: CGFloat = 12
        static let optionalTagSpacing: CGFloat = 8
        static let optionalDotSize: CGFloat = 5
        static let descriptionLabelSpacing: CGFloat = 8
        static let descriptionHeight: CGFloat = 128
        static let descriptionCornerRadius: CGFloat = 10
        static let descriptionHorizontalPadding: CGFloat = 13
        static let descriptionVerticalPadding: CGFloat = 16
        /// TextEditor's built-in text inset, subtracted so typed text lines up with the placeholder.
        static let textEditorInset = CGSize(width: 5, height: 8)
        static let publishButtonWidth: CGFloat = 200
        static let publishButtonHeight: CGFloat = 49
        static let disabledOpacity: CGFloat = 0.4
        /// Longest edge, in pixels, of each photo sent with a new listing.
        static let uploadImageMaxDimension: CGFloat = 512

        static let sheetCornerRadius: CGFloat = 20
        static let sheetTopPadding: CGFloat = 8
        static let sheetBottomPadding: CGFloat = 36
        static let sheetSectionSpacing: CGFloat = 40
        static let sheetHeaderSpacing: CGFloat = 20
        static let grabberSize = CGSize(width: 65.5, height: 6)
        static let chipSpacing: CGFloat = 12
        static let chipPadding: CGFloat = 12
        static let chipBorderWidth: CGFloat = 1
        static let selectedChipBorderWidth: CGFloat = 2
        static let sheetFooterWidth: CGFloat = 296
        static let sheetButtonHeight: CGFloat = 40
        static let sheetButtonHorizontalPadding: CGFloat = 16

        static let categories = ["Clothing", "Books", "School", "Electronics", "Sports & Outdoors", "Other"]
        static let conditions = ["Gently Used", "Used", "Never Used"]
    }

    /// Notifications for pub/sub
    enum Notifications {
        static let LogoutUser = Notification.Name("LogoutUser")
        static let NewListingCreated = Notification.Name("NewListingCreated")
        /// Fired by `FirebaseNotificationService` whenever Firebase hands us a
        /// (new) FCM registration token. `userInfo["token"]` holds the string.
        /// Subscribers are responsible for syncing the value with the backend.
        static let FCMTokenUpdated = Notification.Name("FCMTokenUpdated")

        /// Posted when the user opens a push notification that includes a `transactionId`
        /// (same key in FCM `userInfo`). `userInfo["transactionId"]` is the backend id string.
        /// `MainTabView` routes to reviews if the sale is already completed, else Notifications.
        static let OpenTransactionDeepLink = Notification.Name("ResellOpenTransactionDeepLink")
        /// Posted when the buyer submits a review; `userInfo["transactionId"]` is the backend id.
        static let TransactionReviewSubmitted = Notification.Name("ResellTransactionReviewSubmitted")
    }

    /// Chat  categories used in Resell's design system
    static let chats = [
        FilterCategory(id: 0, title: ChatTab.purchases.rawValue),
        FilterCategory(id: 1, title: ChatTab.offers.rawValue),
        FilterCategory(id: 2, title: ChatTab.archived.rawValue)
    ]
    
    // TODO: Use this whenever working with conditions
    static let conditions = [
        FilterCategory(id: 0, title: "Never Used"),
        FilterCategory(id: 1, title: "Gently Used"),
        FilterCategory(id: 2, title: "Worn")
    ]

    /// Product filter categories used in Resell's design system
    static let filters = [
        FilterCategory(id: 0, title: "Recent"),
        FilterCategory(id: 1, title: "Clothing", color: Constants.Colors.filterPink),
        FilterCategory(id: 2, title: "Books", color: Constants.Colors.filterGreen) ,
        FilterCategory(id: 3, title: "School", color: Constants.Colors.filterLightGreen),
        FilterCategory(id: 4, title: "Electronics", color: Constants.Colors.filterPink),
        FilterCategory(id: 5, title: "Household", color: Constants.Colors.purpleWash),
        FilterCategory(id: 6, title: "Active", color: Constants.Colors.filterBlue),
        FilterCategory(id: 7, title: "Other", color: Constants.Colors.filterGray)
    ]

    /// The categories a listing can belong to: `filters` without the "Recent"
    /// pseudo-category, which is the only entry with no `color`.
    static let productCategories = filters.filter { $0.color != nil }

    /// Events a listing can be tagged with, in the order Explore and the Sell
    /// picker show them. The backend matches tag names exactly and creates any
    /// it hasn't seen, so a tag must not change once listings use it.
    static let eventSpaces = [
        EventSpace(tag: "homecoming", title: "Homecoming"),
        EventSpace(tag: "halloween", title: "Halloween"),
        EventSpace(tag: "formal", title: "Formal"),
        EventSpace(tag: "stpatricks", title: "St. Patrick's Day")
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
//        .sendAvailability,
        .venmo
//        .viewAvailability
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

struct FilterCategory: Identifiable, Hashable {
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
//    case sendAvailability = "Send Availability"
    case venmo = "Pay with Venmo"
//    case viewAvailability = "View Availability"
}
