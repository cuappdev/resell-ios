//
//  MessagesView.swift
//  Resell
//
//  Created by Richie Sun on 10/26/24.
//

import Kingfisher
import PhotosUI
import SwiftUI

struct MessagesView: View {

    // MARK: - Properties

    @EnvironmentObject var router: Router
    @State private var didShowOptionsMenu: Bool = false
    @State private var didShowNegotiationView: Bool = false
    @State private var didShowAvailabilityView: Bool = false
    @State private var didShowWebView: Bool = false
    @State private var isEditing: Bool = true
    @State private var availabilityProposerName: String = ""
    @State private var selectedCells: Set<CellIdentifier> = []
    @State private var priceText: String = ""
    @State private var locallyRespondedProposals: Set<Int> = []  // Track proposals we've responded to locally
    @State private var locallyAcceptedMeeting: Bool = false  // Track if we just accepted a meeting (immediate UI feedback)
    @StateObject private var viewModel: ViewModel
    

    // MARK: - Init

    init(chatInfo: ChatInfo) {
        _viewModel = StateObject(wrappedValue: ViewModel(chatInfo: chatInfo))
    }

    // MARK: - UI

    var body: some View {
        ZStack {
            mainContentView

            if didShowOptionsMenu {
                optionsMenuOverlay
            }
        }
        .background(Constants.Colors.white)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Constants.Colors.white, for: .automatic)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    router.pop()
                } label: {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 20)
                        .foregroundStyle(Constants.Colors.black)
                }
            }
                
            ToolbarItem(placement: .principal) {
                headerButton
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    calendarButton
                    optionsButton
                }
            }
        }
        .sheet(isPresented: $didShowNegotiationView, onDismiss: setNegotiationText) {
            negotiationView
        }
        .sheet(isPresented: $didShowAvailabilityView) {
            availabilityView
        }
        .sheet(isPresented: $didShowWebView) {
            webView
        }
        .onAppear(perform: setupOnAppear)
        .onDisappear {
            FirestoreManager.shared.stopListeningToChat()
        }
        .endEditingOnTap()
    }

    // MARK: - Extracted Subviews

    private var mainContentView: some View {
        VStack {
            messageListView

            Spacer()

            Divider()

            messageInputView
        }
    }

    private var optionsMenuOverlay: some View {
        OptionsMenuView(showMenu: $didShowOptionsMenu, options: [.report(type: "User", id: otherUser.firebaseUid)])
            .zIndex(100)
    }
    
    private var otherUser: User {
        guard let user = GoogleAuthManager.shared.user else {
            return viewModel.chatInfo.buyer
        }
        return viewModel.chatInfo.buyer.firebaseUid == user.firebaseUid ? viewModel.chatInfo.seller : viewModel.chatInfo.buyer
    }
    
    private var calendarButton: some View {
        Button {
            didShowAvailabilityView.toggle()
        } label: {
            Image("calendar")
                .resizable()
                .frame(width: 24, height: 24)
        }
    }
    
    private var headerButton: some View {
        Button {
            navigateToProductDetails()
        } label: {
            VStack(alignment: .center, spacing: 0) {
                Text("\(otherUser.givenName) \(otherUser.familyName)")
                    .font(Constants.Fonts.title1)
                    .foregroundStyle(Constants.Colors.black)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(viewModel.chatInfo.listing.title)
                    .font(Constants.Fonts.title3)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }
    
    private var optionsButton: some View {
        Button {
            withAnimation {
                didShowOptionsMenu.toggle()
            }
        } label: {
            Image(systemName: "ellipsis")
                .resizable()
                .frame(width: 24, height: 6)
                .foregroundStyle(Constants.Colors.black)
        }
    }
    
    private var messageListView: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messageClusters, id: \.id) { cluster in
                            messageCluster(cluster: cluster)
                        }

                        Color.clear.frame(height: 1).id("BOTTOM")
                    }
                }
                .background(Constants.Colors.white)
                .onChange(of: viewModel.messageClusters) { _ in
                    withAnimation {
                        proxy.scrollTo("BOTTOM", anchor: .bottom)
                    }
                }
                .onAppear {
                    withAnimation {
                        proxy.scrollTo("BOTTOM", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var messageInputView: some View {
        VStack(spacing: 12) {
            filtersView
            textInputView
        }
    }

    private var filtersView: some View {
        FilterOptionsView(
            didShowNegotiationView: $didShowNegotiationView,
            didShowAvailabilityView: $didShowAvailabilityView, 
            didShowWebView: $didShowWebView,
            isEditing: $isEditing,
            viewModel: viewModel
        )
    }

    /// Get all proposal times that have been responded to (accepted != nil)
    /// Combines local tracking (immediate) with Firestore messages
    private var respondedProposalTimeIntervals: Set<Int> {
        var times = locallyRespondedProposals  // Start with locally tracked responses
        for cluster in viewModel.messageClusters {
            for message in cluster.messages {
                if let proposal = message as? ProposalMessage,
                   proposal.accepted != nil {
                    // Round to nearest minute for reliable comparison
                    let roundedTime = Int(proposal.startDate.timeIntervalSince1970 / 60)
                    times.insert(roundedTime)
                }
            }
        }
        return times
    }
    
    /// Check if there's an active confirmed meeting (accepted=true, not cancelled)
    /// If true, no other proposals can be accepted until this one is cancelled
    private var hasActiveConfirmedMeeting: Bool {
        // Check local state first
        if locallyAcceptedMeeting {
            return true
        }
        
        // Track which meeting times have been accepted vs cancelled
        var acceptedTimes = Set<Int>()
        var cancelledTimes = Set<Int>()
        
        for cluster in viewModel.messageClusters {
            for message in cluster.messages {
                if let proposal = message as? ProposalMessage {
                    let roundedTime = Int(proposal.startDate.timeIntervalSince1970 / 60)
                    
                    if proposal.accepted == true {
                        acceptedTimes.insert(roundedTime)
                    }
                    if proposal.cancellation == true {
                        cancelledTimes.insert(roundedTime)
                    }
                }
            }
        }
        
        // There's an active meeting if any accepted time hasn't been cancelled
        for acceptedTime in acceptedTimes {
            if !cancelledTimes.contains(acceptedTime) {
                return true
            }
        }
        
        return false
    }
    
    private func messageCluster(cluster: MessageCluster) -> some View {
        return VStack(spacing: 2) {
            if let first = cluster.messages.first {
                Text("\(first.timestamp.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .padding(10)
            }

            ForEach(cluster.messages, id: \.hashValue) { message in
                MessageBubbleView(
                    didShowAvailabilityView: $didShowAvailabilityView,
                    isEditing: $isEditing,
                    availabilityProposerName: $availabilityProposerName,
                    selectedAvailabilities: $viewModel.availability, 
                    message: message,
                    chatInfo: viewModel.chatInfo,
                    onProposalResponse: { startDate, endDate, accepted in
                        // Immediately track this proposal as responded to hide Accept/Decline
                        let roundedTime = Int(startDate.timeIntervalSince1970 / 60)
                        locallyRespondedProposals.insert(roundedTime)
                        
                        // If accepting, mark that we have an active meeting
                        if accepted {
                            locallyAcceptedMeeting = true
                        }
                        
                        Task {
                            do {
                                let transactionId = try await viewModel.respondToProposal(
                                    startDate: startDate,
                                    endDate: endDate,
                                    accepted: accepted
                                )
                                if accepted, let txId = transactionId {
                                    print("Transaction created: \(txId)")
                                }
                            } catch {
                                NetworkManager.shared.logger.error("Error responding to proposal: \(error)")
                            }
                        }
                    },
                    respondedProposalTimeIntervals: respondedProposalTimeIntervals,
                    hasActiveConfirmedMeeting: hasActiveConfirmedMeeting
                )
            }
        }
    }

    private var textInputView: some View {
        TextInputView(draftMessageText: $viewModel.draftMessageText) { text, images in
            let b46Images = images?.compactMap { $0.toBase64() } ?? []
            Task {
                do {
                    try await viewModel.sendMessage(text: text, imagesBase64: b46Images)
                } catch {
                    NetworkManager.shared.logger.error("Error in \(#file) \(#function): \(error)")
                }
            }
        }
    }

    private var negotiationView: some View {
        NegotiationSheetView(
            chatInfo: viewModel.chatInfo,
            priceText: $priceText,
            isPresented: $didShowNegotiationView
        )
    }
    
    private var availabilityView: some View {
        MessagesAvailabilitySheet(
            isPresented: $didShowAvailabilityView,
            selectedCells: $selectedCells,
            isEditing: isEditing,
            proposerName: availabilityProposerName,
            buyerId: viewModel.chatInfo.buyer.firebaseUid,
            sellerId: viewModel.chatInfo.seller.firebaseUid
        ) { startDate, endDate in
            // On propose: send a proposal message with the selected time slot
            Task {
                do {
                    try await viewModel.sendMessage(startDate: startDate, endDate: endDate)
                } catch {
                    NetworkManager.shared.logger.error("Error sending proposal in \(#file) \(#function): \(error)")
                }
            }
        }
        .presentationCornerRadius(25)
        .presentationDragIndicator(.hidden)
        .onAppear {
            // Initialize cells from viewModel.availability when viewing someone's availability
            if !isEditing {
                selectedCells = AvailabilityGridView.availabilitiesToCells(viewModel.availability)
            }
        }
        .onDisappear {
            // Reset for next time
            selectedCells = []
        }
    }

    private var webView: some View {
        Group {
            if let url = viewModel.venmoURL {
                WebView(url: url)
                    .edgesIgnoringSafeArea(.all)
            } else {
                EmptyView()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupOnAppear() {
        guard GoogleAuthManager.shared.user != nil else {
            GoogleAuthManager.shared.logger.error("Error in \(#file) \(#function): User not available.")
            return
        }

        viewModel.parsePayWithVenmoURL()

        Task {
            try await viewModel.getOrCreateChatId()
            viewModel.subscribeToChat()
        }
    }
    
    private func navigateToProductDetails() {
        let post = viewModel.chatInfo.listing
        if let existingIndex = router.path.firstIndex(where: {
            if case let .productDetails(existingPost) = $0, existingPost.id == post.id {
                return true
            }
            return false
        }) {
            router.popTo(router.path[existingIndex])
        } else {
            router.push(.productDetails(post))
        }
    }

    private func setNegotiationText() {
        viewModel.draftMessageText = "Hi! I'm interested in buying your \(viewModel.chatInfo.listing.title), but would you be open to selling it for $\(priceText)?"
        priceText = ""
    }
}

// MARK: - Filter Options View

struct FilterOptionsView: View {
    @Binding var didShowNegotiationView: Bool
    @Binding var didShowAvailabilityView: Bool
    @Binding var didShowWebView: Bool
    @Binding var isEditing: Bool
    let viewModel: MessagesView.ViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(Constants.chatMessageOptions, id: \.self) { option in
                    switch option {
                    case .negotiate:
                        chatOption(title: option.rawValue) {
                            withAnimation { didShowNegotiationView = true }
                        }
//                    case .sendAvailability:
//                        chatOption(title: option.rawValue) {
//                            isEditing = true
//                            withAnimation { didShowAvailabilityView = true }
//                        }
                    case .venmo:
                        chatOption(title: option.rawValue) {
                            withAnimation { didShowWebView = true }
                        }
//                    case .viewAvailability:
//                        // TODO: Fix this logic. There should be two cases, one for the current user and another for the user we're viewing
//                        chatOption(title: "View \(viewModel.chatInfo.listing.user?.givenName ?? "")'s Availability") {
//                            isEditing = false
//                            withAnimation { didShowAvailabilityView = true }
//                        }
            
                    }
                }
            }
            .padding(.vertical, 1)
            .padding(.leading, 8)
        }
    }

    private func chatOption(title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(Constants.Fonts.title3)
                .foregroundStyle(Constants.Colors.black)
                .lineLimit(1)
        }
        .padding(12)
        .overlay {
            RoundedRectangle(cornerRadius: 25)
                .stroke(Constants.Colors.resellGradient, lineWidth: 2)
        }
    }
}

// MARK: - Negotiation Sheet View

struct NegotiationSheetView: View {
    let chatInfo: ChatInfo?
    @Binding var priceText: String
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                KFImage(URL(string: chatInfo?.listing.images[0] ?? ""))
                    .placeholder {
                        ShimmerView()
                            .frame(width: 128, height: 100)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 128, height: 100)
                    .clipShape(.rect(cornerRadius: 18))

                VStack(alignment: .leading, spacing: 8) {
                    Text(chatInfo?.listing.title ?? "")
                        .font(Constants.Fonts.h2)
                        .foregroundStyle(Constants.Colors.black)

                    Text("$\(chatInfo?.listing.originalPrice ?? "0")")
                        .font(Constants.Fonts.body1)
                        .foregroundStyle(Constants.Colors.black)
                }

                Spacer()
            }
            .padding(16)
            .frame(width: UIScreen.width - 40, height: 125)
            .background(Constants.Colors.white)
            .clipShape(.rect(cornerRadius: 18))

            PriceInputView(
                price: $priceText,
                isPresented: $isPresented,
                titleText: "What price do you want to propose?"
            )
            .padding(.bottom, 24)
            .background(Constants.Colors.white)
            .clipShape(.rect(cornerRadii: .init(topLeading: 25, topTrailing: 25)))
            .overlay(alignment: .top) {
                Rectangle()
                    .foregroundStyle(Constants.Colors.stroke)
                    .frame(width: 66, height: 6)
                    .clipShape(.capsule)
                    .padding(.top, 12)
            }
        }
        .presentationDetents([.height(UIScreen.height * 3/4)])
        .presentationBackground(.clear)
        .ignoresSafeArea()
    }
}



// MARK: - Messages Availability Sheet
// Replace the existing MessagesAvailabilitySheet in MessagesView.swift with this

struct MessagesAvailabilitySheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedCells: Set<CellIdentifier>
    @EnvironmentObject var router: Router
    
    @State private var gridCurrentPage: Int = 0
    @State private var currentMonthOffset: Int = 0
    @State private var gridStartDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showCalendar: Bool = false
    @State private var visibleGridDates: [Date] = []
    
    // Unavailability states
    @State private var buyerUnavailableCells: Set<CellIdentifier> = []
    @State private var sellerUnavailableCells: Set<CellIdentifier> = []
    @State private var isLoadingAvailability: Bool = false
    
    /// Maximum month offset allowed (1 = can only go one month ahead)
    private let maxMonthOffset: Int = 1

    let isEditing: Bool
    let proposerName: String
    let buyerId: String
    let sellerId: String
    /// Called when user proposes a meeting time with (startDate, endDate)
    let onPropose: (Date, Date) -> Void
    
    private var monthName: String {
        CalendarHelper.monthName(for: currentMonthOffset)
    }

    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 10)
                .frame(width: 66, height: 6)
                .foregroundStyle(Constants.Colors.filterGray)
            
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showCalendar.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(monthName)
                            .font(Constants.Fonts.title1)
                            .foregroundColor(Constants.Colors.black)
                        
                        Image(systemName: showCalendar ? "chevron.up" : "chevron.down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 8)
                            .foregroundColor(Constants.Colors.black)
                    }
                    .padding(.top)
                }

                HStack {
                    Text("Propose a time to meet")
                        .font(Constants.Fonts.body2)
                        .foregroundColor(Constants.Colors.secondaryGray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Divider()
                        .frame(height: 16)
                    
                    Button {
                        isPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            router.push(.availability)
                        }
                    } label: {
                        Text("Edit Availability")
                            .font(Constants.Fonts.title2)
                            .foregroundColor(Constants.Colors.resellPurple)
                    }
                }
            }
            
            // Month calendar - collapsible
            if showCalendar {
                MessagesMonthCalendarView(
                    currentMonthOffset: $currentMonthOffset,
                    gridStartDate: $gridStartDate,
                    visibleGridDates: visibleGridDates,
                    maxMonthOffset: maxMonthOffset,
                    onDateSelected: { selectedDate in
                        gridCurrentPage = 0
                        gridStartDate = selectedDate
                        updateVisibleDates(from: selectedDate, page: 0)
                    }
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Grid - single selection mode for proposing a 30-min meeting slot
            AvailabilityGridView(
                selectedCells: $selectedCells,
                currentPage: $gridCurrentPage,
                isEditing: isEditing,
                singleSelectionMode: true,
                startDate: gridStartDate,
                gridHeight: showCalendar ? UIScreen.height * 0.35 : UIScreen.height * 0.625,
                onVisibleDatesChanged: { dates in
                    visibleGridDates = dates
                    if let firstDate = dates.first {
                        let newMonthOffset = CalendarHelper.monthOffset(for: firstDate)
                        // Clamp to max offset
                        let clampedOffset = min(max(newMonthOffset, 0), maxMonthOffset)
                        if clampedOffset != currentMonthOffset {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentMonthOffset = clampedOffset
                            }
                        }
                    }
                },
                buyerUnavailableCells: buyerUnavailableCells,
                sellerUnavailableCells: sellerUnavailableCells
            )
            .id(gridStartDate)
            
            Spacer()
            
            // Action Button - only enabled when a time slot is selected
            PurpleButton(isActive: !selectedCells.isEmpty, text: "Propose") {
                if let selectedCell = selectedCells.first,
                   let availability = AvailabilityGridView.cellsToAvailabilities([selectedCell]).first {
                    onPropose(availability.startDate, availability.endDate)
                    isPresented = false
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 32)
        .background(Constants.Colors.white)
        .onAppear {
            updateVisibleDates(from: gridStartDate, page: 0)
            Task {
                await loadUnavailability()
            }
        }
        .onChange(of: currentMonthOffset) { newOffset in
            let calendar = Calendar.current
            let today = Date()
            
            if let targetMonth = calendar.date(byAdding: .month, value: newOffset, to: today),
               let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: targetMonth)) {
                
                let startOfToday = calendar.startOfDay(for: today)
                let newStartDate = (newOffset == 0 && firstOfMonth < startOfToday) ? startOfToday : firstOfMonth
                
                let gridMonth = calendar.component(.month, from: gridStartDate)
                let gridYear = calendar.component(.year, from: gridStartDate)
                let targetMonthComponent = calendar.component(.month, from: firstOfMonth)
                let targetYearComponent = calendar.component(.year, from: firstOfMonth)
                
                if gridMonth != targetMonthComponent || gridYear != targetYearComponent {
                    gridStartDate = newStartDate
                    gridCurrentPage = 0
                    updateVisibleDates(from: newStartDate, page: 0)
                }
            }
        }
    }
    
    private func updateVisibleDates(from startDate: Date, page: Int) {
        let calendar = Calendar.current
        let startIndex = page * 3
        visibleGridDates = (0..<3).compactMap { offset in
            calendar.date(byAdding: .day, value: startIndex + offset, to: startDate)
        }
    }
    
    // MARK: - Availability Loading
    
    private func loadUnavailability() async {
        isLoadingAvailability = true
        defer { isLoadingAvailability = false }
        
        // Fetch buyer and seller availability in parallel
        async let buyerAvailabilityResult = fetchAvailability(for: buyerId)
        async let sellerAvailabilityResult = fetchAvailability(for: sellerId)
        
        let (buyerAvailable, sellerAvailable) = await (buyerAvailabilityResult, sellerAvailabilityResult)
        
        // Convert availability to unavailability (cells NOT in their available set are unavailable)
        let buyerUnavailable = computeUnavailableCells(from: buyerAvailable)
        let sellerUnavailable = computeUnavailableCells(from: sellerAvailable)
        
        await MainActor.run {
            buyerUnavailableCells = buyerUnavailable
            sellerUnavailableCells = sellerUnavailable
        }
    }
    
    private func fetchAvailability(for userId: String) async -> Set<CellIdentifier> {
        do {
            let response = try await NetworkManager.shared.getAvailabilityByUserID(id: userId)
            return scheduleToAvailableCells(response.availability.schedule)
        } catch {
            print("Failed to fetch availability for user \(userId): \(error)")
            return []
        }
    }
    
    /// Converts API schedule format to available cell identifiers
    private func scheduleToAvailableCells(_ schedule: [String: [AvailabilitySlot]]) -> Set<CellIdentifier> {
        var cells = Set<CellIdentifier>()
        
        for (_, slots) in schedule {
            for slot in slots {
                let availability = Availability(startDate: slot.startDate, endDate: slot.endDate)
                let cellsForSlot = AvailabilityGridView.availabilitiesToCells([availability])
                cells.formUnion(cellsForSlot)
            }
        }
        
        return cells
    }
    
    /// Computes unavailable cells by finding all cells NOT in the available set
    /// Only considers dates within the grid's range (next 30 days from today)
    private func computeUnavailableCells(from availableCells: Set<CellIdentifier>) -> Set<CellIdentifier> {
        var unavailableCells = Set<CellIdentifier>()
        
        // Generate all possible cells for the grid's date range
        let allDates = CalendarHelper.generateGridDates(startingFrom: Calendar.current.startOfDay(for: Date()))
        let times = generateTimes()
        
        for date in allDates {
            for time in times {
                let topIdentifier = CellIdentifier(date: date, time: "\(time) Top")
                let bottomIdentifier = CellIdentifier(date: date, time: "\(time) Bottom")
                
                // If not in available cells, it's unavailable
                if !availableCells.contains(topIdentifier) {
                    unavailableCells.insert(topIdentifier)
                }
                if !availableCells.contains(bottomIdentifier) {
                    unavailableCells.insert(bottomIdentifier)
                }
            }
        }
        
        return unavailableCells
    }
}

// MARK: - Messages Month Calendar View (with max offset restriction)

struct MessagesMonthCalendarView: View {
    @Binding var currentMonthOffset: Int
    @Binding var gridStartDate: Date
    
    var visibleGridDates: [Date] = []
    var maxMonthOffset: Int = 1
    var onDateSelected: ((Date) -> Void)?
    
    private var monthData: CalendarMonthData {
        CalendarHelper.generateMonthData(monthOffset: currentMonthOffset)
    }
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let cellHeight: CGFloat = 36
    private let rowSpacing: CGFloat = 6
    
    var body: some View {
        VStack(spacing: 10) {
            weekdayHeader
            
            GeometryReader { geometry in
                let cellWidth = geometry.size.width / 7
                
                ZStack(alignment: .topLeading) {
                    selectionBackgroundLayer(cellWidth: cellWidth)
                    
                    LazyVGrid(columns: columns, spacing: rowSpacing) {
                        ForEach(monthData.days) { day in
                            dayCell(for: day)
                        }
                    }
                }
            }
            .frame(height: CGFloat(5) * cellHeight + CGFloat(4) * rowSpacing)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let verticalDrag = value.translation.height
                    let horizontalDrag = abs(value.translation.width)
                    
                    if abs(verticalDrag) > horizontalDrag {
                        if verticalDrag < -50 {
                            // Swipe up - next month (respect max offset)
                            if currentMonthOffset < maxMonthOffset {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    currentMonthOffset += 1
                                }
                            }
                        } else if verticalDrag > 50 {
                            // Swipe down - previous month (don't go before current)
                            if currentMonthOffset > 0 {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    currentMonthOffset -= 1
                                }
                            }
                        }
                    }
                }
        )
    }
    
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(CalendarMonthData.weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func selectionBackgroundLayer(cellWidth: CGFloat) -> some View {
        let visibleDaysInMonth = monthData.days.filter { day in
            visibleGridDates.contains { Calendar.current.isDate($0, inSameDayAs: day.date) }
        }
        
        let rowGroups = Dictionary(grouping: visibleDaysInMonth) { $0.rowIndex }
        let sortedRowIndices = rowGroups.keys.sorted()
        
        return ZStack(alignment: .topLeading) {
            ForEach(sortedRowIndices, id: \.self) { rowIndex in
                if let daysInRow = rowGroups[rowIndex] {
                    let sortedDays = daysInRow.sorted { $0.weekdayIndex < $1.weekdayIndex }
                    if let firstDay = sortedDays.first, let lastDay = sortedDays.last {
                        let startX = CGFloat(firstDay.weekdayIndex) * cellWidth
                        let width = CGFloat(lastDay.weekdayIndex - firstDay.weekdayIndex + 1) * cellWidth
                        let y = CGFloat(rowIndex) * (cellHeight + rowSpacing)
                        
                        let isFirstRow = rowIndex == sortedRowIndices.first
                        let isLastRow = rowIndex == sortedRowIndices.last
                        let continuesFromAbove = sortedRowIndices.contains(rowIndex - 1)
                        let continuesToBelow = sortedRowIndices.contains(rowIndex + 1)
                        
                        let rowAboveEndedAtSaturday: Bool = {
                            if let aboveRow = rowGroups[rowIndex - 1] {
                                return aboveRow.contains { $0.weekdayIndex == 6 }
                            }
                            return false
                        }()
                        
                        let startsAtSunday = firstDay.weekdayIndex == 0
                        let endsAtSaturday = lastDay.weekdayIndex == 6
                        
                        SelectionRowShape(
                            cornerRadius: 10,
                            roundTopLeft: isFirstRow || (startsAtSunday && !rowAboveEndedAtSaturday),
                            roundTopRight: isFirstRow || !endsAtSaturday,
                            roundBottomLeft: isLastRow || !startsAtSunday,
                            roundBottomRight: isLastRow || !continuesToBelow
                        )
                        .fill(Constants.Colors.wash)
                        .frame(width: width, height: cellHeight)
                        .offset(x: startX, y: y)
                    }
                }
            }
        }
    }
    
    private func dayCell(for day: CalendarDay) -> some View {
        Text("\(day.dayNumber)")
            .font(Constants.Fonts.body2)
            .foregroundStyle(dayTextColor(for: day))
            .frame(maxWidth: .infinity)
            .frame(height: cellHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                guard day.isSelectable else { return }
                // Check if the date is within allowed range (current month or next month)
                let dateMonthOffset = CalendarHelper.monthOffset(for: day.date)
                guard dateMonthOffset <= maxMonthOffset else { return }
                
                let selectedDate = Calendar.current.startOfDay(for: day.date)
                gridStartDate = selectedDate
                onDateSelected?(selectedDate)
            }
    }
    
    private func dayTextColor(for day: CalendarDay) -> Color {
        if day.isToday && day.isCurrentMonth {
            return Constants.Colors.errorRed
        }
        
        if !day.isCurrentMonth {
            return Constants.Colors.secondaryGray.opacity(0.5)
        } else if day.isPast {
            return Constants.Colors.secondaryGray.opacity(0.5)
        } else {
            return Constants.Colors.black
        }
    }
}

// MARK: - MessageBubbleView

struct MessageBubbleView: View {

    @Binding var didShowAvailabilityView: Bool
    @Binding var isEditing: Bool
    @Binding var availabilityProposerName: String
    @Binding var selectedAvailabilities: [Availability]

    let message: any Message
    let chatInfo: ChatInfo
    
    /// Callback for responding to proposals (startDate, endDate, accepted)
    var onProposalResponse: ((Date, Date, Bool) -> Void)?
    
    /// Set of proposal times that have already been responded to (startDate as minutes since epoch)
    var respondedProposalTimeIntervals: Set<Int> = []
    
    /// Whether there's an active confirmed meeting in this chat (blocks accepting other proposals)
    var hasActiveConfirmedMeeting: Bool = false

    var body: some View {
        if message.messageType == .proposal {
            proposalMessageView
                .padding(.horizontal, 24)
        } else {
            HStack {
                if message.mine {
                    Spacer()
                }

                messageContentView
                    .padding(.leading, message.mine ? 64 : 0)
                    .padding(.trailing, message.mine ? 0 : 64)

                if !message.mine {
                    Spacer()
                }
            }
            .padding(.horizontal, 12)
        }
    }

    @ViewBuilder
    private var messageContentView: some View {
        switch message.messageType {
        case .chat:
            chatMessageView
        case .availability:
            availabilityMessageView
        case .proposal:
            EmptyView() // Handled separately in body
        }
    }

    @ViewBuilder
    private var chatMessageView: some View {
        if let message = message as? ChatMessage {
            VStack() {
                if !message.text.isEmpty {
                    textBubbleView(message: message)
                }

                ForEach(message.images, id: \.self) { image in
                    imageView(imageUrl: image)
                }
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func textBubbleView(message: ChatMessage) -> some View {
        HStack {
            VStack(alignment: message.mine ? .trailing : .leading, spacing: 8) {
                Text(message.text)
                    .font(Constants.Fonts.body2)
                    .foregroundStyle(message.mine ? Constants.Colors.white : Constants.Colors.black)

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(message.mine ? Constants.Colors.white : Constants.Colors.secondaryGray)
            }
            .padding(12)
            .background(message.mine ? (message.sent ? Constants.Colors.resellPurple : Constants.Colors.resellPurple.opacity(0.5)) : Constants.Colors.wash)
            .foregroundColor(message.mine ? Constants.Colors.white : Constants.Colors.black)
            .cornerRadius(10)
        }
    }

    @ViewBuilder
    private func imageView(imageUrl: String) -> some View {
        HStack {
            if message.mine {
                Spacer()
            }

            if let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } placeholder: {
                    ProgressView()
                }
            }

            if !message.mine {
                Spacer()
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var availabilityMessageView: some View {
        if let message = message as? AvailabilityMessage {
            Button {
                selectedAvailabilities = message.availabilities
                availabilityProposerName = message.from.givenName
                didShowAvailabilityView = true
                isEditing = false
            } label: {
                HStack {
                    // TODO: FIX
                    Text("\(message.from.givenName)'s Availability")
                        .font(Constants.Fonts.title2)
                        .foregroundStyle(Constants.Colors.resellPurple)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(Constants.Colors.resellPurple)
                }
                .padding(12)
                .background(Constants.Colors.resellPurple.opacity(0.1))
                .clipShape(.rect(cornerRadius: 10))
                .padding(.vertical, 6)
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var proposalMessageView: some View {
        if let message = message as? ProposalMessage {
            VStack(spacing: 8) {
                // Icon and title
                HStack(spacing: 8) {
                    Image(systemName: message.messageType == .proposal ? "" : "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(Constants.Colors.black)
                    
                    Text(proposalTitle(for: message))
                        .font(Constants.Fonts.body1)
                        .foregroundColor(Constants.Colors.black)
                        .multilineTextAlignment(.center)
                }
                
                // Action buttons (only show if pending, not cancelled, I'm not the proposer, not already responded, and no active confirmed meeting)
                let roundedTime = Int(message.startDate.timeIntervalSince1970 / 60)
                let alreadyResponded = respondedProposalTimeIntervals.contains(roundedTime)
                // Can't accept/decline if there's already an active confirmed meeting
                let canShowActions = message.accepted == nil && message.cancellation != true && !message.mine && !alreadyResponded && !hasActiveConfirmedMeeting
                if canShowActions {
                    HStack(spacing: 32) {
                        Button {
                            onProposalResponse?(message.startDate, message.endDate, true)
                        } label: {
                            Text("Accept")
                                .font(Constants.Fonts.title2)
                                .foregroundColor(Constants.Colors.resellPurple)
                        }
                        
                        Button {
                            onProposalResponse?(message.startDate, message.endDate, false)
                        } label: {
                            Text("Decline")
                                .font(Constants.Fonts.title2)
                                .foregroundColor(Constants.Colors.errorRed)
                        }
                    }
                }
                
                // View Details button for confirmed meetings
                if message.accepted == true {
                    Button {
                        // TODO: Show meeting details
                    } label: {
                        Text("View Details")
                            .font(Constants.Fonts.title2)
                            .foregroundColor(Constants.Colors.resellPurple)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        } else {
            EmptyView()
        }
    }
    
    // MARK: - Proposal Helpers
    
    private func proposalTitle(for message: ProposalMessage) -> String {
        let proposerName = message.from.givenName
        let timeString = formatProposalTime(start: message.startDate, end: message.endDate)
        
        if message.cancellation == true {
            if message.mine {
                return "You cancelled the meeting"
            } else {
                return "\(proposerName) cancelled the meeting"
            }
        }
        
        switch message.accepted {
        case nil:
            if message.mine {
                return "You proposed to meet at:\n\(timeString)"
            } else {
                return "\(proposerName) wants to meet at:\n\(timeString)"
            }
        case true:
            return "The meeting has been confirmed"
        case false:
            return "The meeting was declined"
        }
    }
    
    private func formatProposalTime(start: Date, end: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, h:mm a"
        return dateFormatter.string(from: start)
    }

}



// MARK: - TextInputView

struct TextInputView: View {

    // MARK: - Properties

    @State private var selectedImages: [UIImage] = []
    @State private var showingPhotoPicker = false
    @Binding var draftMessageText: String

    let onSend: (String?, [UIImage]?) -> Void
    let maxCharacters: Int = 1000

    // MARK: - UI

    var body: some View {
        VStack(spacing: 8) {
            // Image preview section
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<selectedImages.count, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                Button(action: {
                                    selectedImages.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .shadow(radius: 2)
                                        .padding(4)
                                }
                            }
                        }
                    }
                    .padding(.leading, 32)
                }
            }

            HStack {
                Button {
                    showingPhotoPicker = true
                } label: {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Constants.Colors.secondaryGray)
                }
                .sheet(isPresented: $showingPhotoPicker) {
                    ImagePicker(selectedImages: $selectedImages)
                }

                TextEditor(text: $draftMessageText)
                    .font(Constants.Fonts.body2)
                    .foregroundColor(Constants.Colors.black)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(Constants.Colors.wash)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .frame(height: 48)
                    .onChange(of: draftMessageText) { newText in
                        if newText.count > maxCharacters {
                            draftMessageText = String(newText.prefix(maxCharacters))
                        }
                    }

                if !draftMessageText.isEmpty || !selectedImages.isEmpty {
                    Button(action: {
                        onSend(draftMessageText.isEmpty ? nil : draftMessageText, selectedImages.isEmpty ? nil : selectedImages)
                        draftMessageText = ""
                        selectedImages = []
                    }) {
                        Image("sendButton")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                    .padding(.trailing, 8)
                }
            }
        }
        .padding(.trailing, 24)
        .padding(.leading, 8)
    }
}

// MARK: - ImagePicker View

struct SingleImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: SingleImagePicker

        init(_ parent: SingleImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
