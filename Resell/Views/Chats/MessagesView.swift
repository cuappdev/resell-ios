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
    /// Firestore messageIds of proposal messages the user has locally tapped
    /// Accept/Decline on. Keyed by messageId (not slot) so that a brand-new
    /// proposal at the same slot as an older, already-handled proposal does not
    /// inherit the old "already responded" state.
    @State private var locallyRespondedMessageIds: Set<String> = []
    /// Optimistic slot-level overrides applied on top of Firestore. The value
    /// is the latest local decision for the slot: `isAccepted: true` when the
    /// user tapped Accept (slot becomes "active"), `false` when they tapped
    /// Cancel (slot becomes "cancelled"). Decline has no slot-level effect
    /// (only the specific message is hidden, via `locallyRespondedMessageIds`).
    @State private var localSlotOverrides: [ProposalSlot: (isAccepted: Bool, endDate: Date)] = [:]
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

    /// Latest accept/cancel state for each slot, derived from all proposal
    /// messages in the chat (sorted by timestamp — the most recent event
    /// determines the slot's current state) with local optimistic overrides
    /// layered on top.
    ///
    /// Why latest-event-per-slot instead of aggregating? A slot can legitimately
    /// cycle through accepted → cancelled → accepted → cancelled → accepted as
    /// both parties re-propose the same time. Aggregating would permanently
    /// poison the slot's state once a cancel exists anywhere in history.
    private var latestSlotStates: [ProposalSlot: (isAccepted: Bool, endDate: Date)] {
        var states: [ProposalSlot: (isAccepted: Bool, endDate: Date)] = [:]

        let allMessages = viewModel.messageClusters
            .flatMap(\.messages)
            .sorted { $0.timestamp < $1.timestamp }

        for message in allMessages {
            guard let proposal = message as? ProposalMessage else { continue }
            let slot = ProposalSlot(startDate: proposal.startDate, endDate: proposal.endDate)

            // A cancellation message always represents the most recent
            // intent on its slot, regardless of whether `accepted` is also
            // set on the same document.
            if proposal.cancellation == true {
                states[slot] = (false, proposal.endDate)
            } else if proposal.accepted == true {
                states[slot] = (true, proposal.endDate)
            }
        }

        // Local optimistic actions are always newer than any Firestore event.
        for (slot, override) in localSlotOverrides {
            states[slot] = (override.isAccepted, override.endDate)
        }

        return states
    }

    /// Slots whose most recent state is "cancelled". Passed into bubbles so a
    /// previously-confirmed-then-cancelled meeting hides its Cancel button.
    /// Importantly, if that same slot is later accepted again (new proposal,
    /// user accepts), the slot is NO LONGER in this set — so the new meeting's
    /// Cancel button correctly appears.
    private var currentlyCancelledSlots: Set<ProposalSlot> {
        Set(latestSlotStates.compactMap { slot, state in state.isAccepted ? nil : slot })
    }

    /// Whether any slot in this chat has an active, future confirmed meeting.
    /// Past meetings auto-expire so users aren't permanently locked out of
    /// accepting future proposals.
    private var hasActiveConfirmedMeeting: Bool {
        let now = Date()
        return latestSlotStates.values.contains { $0.isAccepted && $0.endDate > now }
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
                    onProposalResponse: { messageId, startDate, endDate, accepted in
                        // Optimistically hide Accept/Decline on this specific
                        // bubble so the UI feels snappy. If the request fails
                        // we roll these back below.
                        let slot = ProposalSlot(startDate: startDate, endDate: endDate)
                        let hadSlotOverride = localSlotOverrides[slot]
                        locallyRespondedMessageIds.insert(messageId)
                        if accepted {
                            // Accept makes the slot active for the whole chat
                            // so other pending proposals' Accept/Decline hide.
                            localSlotOverrides[slot] = (true, endDate)
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
                                // The network call failed – undo the optimistic UI
                                // update so the user can try again. Without this
                                // rollback the Accept button disappears locally
                                // but nothing was persisted server-side, so the
                                // proposal re-appears the next time the chat
                                // is reopened.
                                NetworkManager.shared.logger.error("Error responding to proposal: \(error)")
                                await MainActor.run {
                                    locallyRespondedMessageIds.remove(messageId)
                                    if accepted {
                                        // Restore whatever override was there
                                        // before we set it (usually nil).
                                        if let prior = hadSlotOverride {
                                            localSlotOverrides[slot] = prior
                                        } else {
                                            localSlotOverrides.removeValue(forKey: slot)
                                        }
                                    }
                                }
                            }
                        }
                    },
                    onProposalCancel: { startDate, endDate in
                        let slot = ProposalSlot(startDate: startDate, endDate: endDate)
                        let priorOverride = localSlotOverrides[slot]
                        // Optimistically mark this slot as cancelled so the
                        // Cancel button hides on this bubble and Accept/Decline
                        // re-enable on any other pending proposals in the chat.
                        localSlotOverrides[slot] = (false, endDate)

                        Task {
                            do {
                                try await viewModel.cancelProposal(startDate: startDate, endDate: endDate)
                            } catch {
                                NetworkManager.shared.logger.error("Error cancelling proposal: \(error)")
                                await MainActor.run {
                                    if let prior = priorOverride {
                                        localSlotOverrides[slot] = prior
                                    } else {
                                        localSlotOverrides.removeValue(forKey: slot)
                                    }
                                }
                            }
                        }
                    },
                    respondedMessageIds: locallyRespondedMessageIds,
                    currentlyCancelledSlots: currentlyCancelledSlots,
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
    /// Mirrors the AvailabilitySettingsView fix: when the grid scrolls across a
    /// month boundary it bumps `currentMonthOffset` itself, so we must skip the
    /// snap-back logic in `onChange(of: currentMonthOffset)` for that one tick.
    /// Otherwise the grid resets to the first of the new month and the user
    /// can't scroll backward across month boundaries.
    @State private var isMonthChangeFromGridScroll: Bool = false

    // Unavailability states
    @State private var buyerUnavailableCells: Set<CellIdentifier> = []
    @State private var sellerUnavailableCells: Set<CellIdentifier> = []
    @State private var isLoadingAvailability: Bool = false
    
    /// Maximum month offset allowed (1 = can only go one month ahead)
    private let maxMonthOffset: Int = 1

    /// Number of days the availability grid should render: from today through
    /// the last day of the capped month. With `maxMonthOffset = 1` this is
    /// "today → end of next month", so users can never page past the cap.
    private var gridDayCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let comps = calendar.dateComponents([.year, .month], from: today)
        guard let firstOfThisMonth = calendar.date(from: comps),
              let firstOfMonthAfterCap = calendar.date(
                byAdding: .month,
                value: maxMonthOffset + 1,
                to: firstOfThisMonth
              ) else {
            return 30
        }
        let days = calendar.dateComponents(
            [.day], from: today, to: firstOfMonthAfterCap
        ).day ?? 30
        return max(days, 1)
    }

    let isEditing: Bool
    let proposerName: String
    let buyerId: String
    let sellerId: String
    /// Called when user proposes a meeting time with (startDate, endDate)
    let onPropose: (Date, Date) -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 10)
                    .frame(width: 66, height: 6)
                    .foregroundStyle(Constants.Colors.filterGray)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                MonthPickerHeader(
                    currentMonthOffset: $currentMonthOffset,
                    showCalendar: $showCalendar,
                    showSettings: .constant(false),
                    maxMonthOffset: maxMonthOffset
                )

                proposeSubheader
                    .padding(.horizontal)
                    .padding(.top, 4)
                    .padding(.bottom, 8)

                if showCalendar {
                    MonthCalendarView(
                        currentMonthOffset: $currentMonthOffset,
                        gridStartDate: $gridStartDate,
                        visibleGridDates: visibleGridDates,
                        onDateSelected: { selectedDate in
                            // The grid is sized (via `gridDayCount`) to cover
                            // exactly today → end-of-capped-month, so the
                            // picked date is always reachable from a
                            // today-anchored grid. Anchoring there means the
                            // user can also scroll backward to any earlier
                            // valid day, and they can never scroll forward
                            // past the cap.
                            let calendar = Calendar.current
                            let startOfToday = calendar.startOfDay(for: Date())
                            let selected = calendar.startOfDay(for: selectedDate)
                            let daysFromToday = max(
                                calendar.dateComponents(
                                    [.day], from: startOfToday, to: selected
                                ).day ?? 0,
                                0
                            )
                            let pageIndex = daysFromToday / 3

                            gridStartDate = startOfToday
                            gridCurrentPage = pageIndex
                            updateVisibleDates(from: startOfToday, page: pageIndex)
                        },
                        onDismiss: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showCalendar = false
                            }
                        },
                        maxMonthOffset: maxMonthOffset
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                }

                AvailabilityGridView(
                    selectedCells: $selectedCells,
                    currentPage: $gridCurrentPage,
                    isEditing: isEditing,
                    singleSelectionMode: true,
                    startDate: gridStartDate,
                    dayCount: gridDayCount,
                    onVisibleDatesChanged: { dates in
                        visibleGridDates = dates
                        if let firstDate = dates.first {
                            let newMonthOffset = CalendarHelper.monthOffset(for: firstDate)
                            let clampedOffset = min(max(newMonthOffset, 0), maxMonthOffset)
                            if clampedOffset != currentMonthOffset {
                                isMonthChangeFromGridScroll = true
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
                .fixedSize(horizontal: false, vertical: true)

                PurpleButton(isActive: !selectedCells.isEmpty, text: "Propose") {
                    if let selectedCell = selectedCells.first,
                       let availability = AvailabilityGridView.cellsToAvailabilities([selectedCell]).first {
                        onPropose(availability.startDate, availability.endDate)
                        isPresented = false
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 24)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .scrollDisabled(true)
        .clipped()
        .background(Constants.Colors.white)
        .onAppear {
            updateVisibleDates(from: gridStartDate, page: 0)
            Task {
                await loadUnavailability()
            }
        }
        .onChange(of: currentMonthOffset) { newOffset in
            // The grid horizontally scrolling across a month boundary mutates
            // currentMonthOffset itself. Re-anchoring gridStartDate in that
            // case would cancel the scroll mid-gesture and prevent the user
            // from going back. Skip exactly one onChange tick in that case.
            if isMonthChangeFromGridScroll {
                isMonthChangeFromGridScroll = false
                return
            }

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

    private var proposeSubheader: some View {
        HStack(spacing: 8) {
            Text("Propose a time to meet")
                .font(Constants.Fonts.body2)
                .foregroundColor(Constants.Colors.secondaryGray)
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

            Spacer()
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
        
        // Generate all possible cells for the grid's date range. Match the
        // visible grid's day count so cells beyond the first 30 days still
        // show buyer/seller unavailability shading.
        let allDates = CalendarHelper.generateGridDates(
            startingFrom: Calendar.current.startOfDay(for: Date()),
            count: gridDayCount
        )
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

// MARK: - MessageBubbleView

struct MessageBubbleView: View {

    @Binding var didShowAvailabilityView: Bool
    @Binding var isEditing: Bool
    @Binding var availabilityProposerName: String
    @Binding var selectedAvailabilities: [Availability]

    let message: any Message
    let chatInfo: ChatInfo
    
    /// Callback for responding to proposals (messageId, startDate, endDate, accepted).
    /// The messageId lets the parent hide Accept/Decline on this exact bubble
    /// without affecting sibling proposals at the same slot.
    var onProposalResponse: ((String, Date, Date, Bool) -> Void)?

    /// Callback for cancelling an already-confirmed proposal (startDate, endDate).
    /// Slot-level because the backend identifies cancellations by slot.
    var onProposalCancel: ((Date, Date) -> Void)?

    /// messageIds the user has locally tapped Accept/Decline on. Used to
    /// instantly hide the action row on that specific bubble while the
    /// network request is in flight.
    var respondedMessageIds: Set<String> = []

    /// Slots whose latest state is "cancelled" (either in Firestore or
    /// optimistically). Used to hide the Cancel button once a cancel is in
    /// flight / confirmed. A slot that was cancelled but later re-accepted
    /// is NOT in this set, so the new confirmed meeting keeps its Cancel button.
    var currentlyCancelledSlots: Set<ProposalSlot> = []

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
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(Constants.Colors.black)
                    
                    Text(proposalTitle(for: message))
                        .font(Constants.Fonts.body1)
                        .foregroundColor(Constants.Colors.black)
                        .multilineTextAlignment(.center)
                }
                
                // Action buttons on a pending, incoming proposal. Hidden as
                // soon as the user taps Accept/Decline on *this* bubble
                // (tracked per-messageId, not per-slot), or when another
                // proposal in the chat is an active confirmed meeting.
                let slot = ProposalSlot(startDate: message.startDate, endDate: message.endDate)
                let alreadyResponded = respondedMessageIds.contains(message.messageId)
                let canShowActions = message.accepted == nil
                    && message.cancellation != true
                    && !message.mine
                    && !alreadyResponded
                    && !hasActiveConfirmedMeeting
                if canShowActions {
                    HStack(spacing: 32) {
                        Button {
                            onProposalResponse?(message.messageId, message.startDate, message.endDate, true)
                        } label: {
                            Text("Accept")
                                .font(Constants.Fonts.title2)
                                .foregroundColor(Constants.Colors.resellPurple)
                        }

                        Button {
                            onProposalResponse?(message.messageId, message.startDate, message.endDate, false)
                        } label: {
                            Text("Decline")
                                .font(Constants.Fonts.title2)
                                .foregroundColor(Constants.Colors.errorRed)
                        }
                    }
                }

                // Actions for confirmed meetings. Cancel shows while the
                // meeting is in the future AND this slot's latest state is
                // still "accepted" (not cancelled elsewhere in the timeline
                // or optimistically in this session).
                if message.accepted == true {
                    let isSlotCancelled = message.cancellation == true
                        || currentlyCancelledSlots.contains(slot)
                    let isUpcoming = message.endDate > Date()

                    HStack(spacing: 32) {
                        Button {
                            // TODO: Show meeting details
                        } label: {
                            Text("View Details")
                                .font(Constants.Fonts.title2)
                                .foregroundColor(Constants.Colors.resellPurple)
                        }

                        if isUpcoming && !isSlotCancelled {
                            Button {
                                onProposalCancel?(message.startDate, message.endDate)
                            } label: {
                                Text("Cancel")
                                    .font(Constants.Fonts.title2)
                                    .foregroundColor(Constants.Colors.errorRed)
                            }
                        }
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
        default:
            return "Status unknown in Message acceptance"
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
