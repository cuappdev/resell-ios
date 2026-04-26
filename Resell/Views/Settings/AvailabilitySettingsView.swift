//
//  AvailabilitySettingsView.swift
//  Resell
//
//  Created by Charles Liggins on 1/12/26.
//

import SwiftUI

struct AvailabilitySettingsView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject var router: Router
    @State private var selectedCells: Set<CellIdentifier> = []
    @State private var currentMonthOffset: Int = 0
    @State private var gridStartDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showCalendar: Bool = false
    @State private var showSettings: Bool = false
    @State private var gridCurrentPage: Int = 0
    @State private var visibleGridDates: [Date] = []
    
    @State private var isLoading: Bool = false
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil

    /// Dates (yyyy-MM-dd) that exist in the saved schedule on the backend.
    /// Tracked so we can send empty arrays for them on save when the user clears cells,
    /// since the backend merges schedule entries instead of replacing the whole dict.
    @State private var knownScheduleDates: Set<String> = []

    /// Set to true when `currentMonthOffset` is being updated as a side effect of
    /// horizontally paging the AvailabilityGridView. Prevents `onChange` from
    /// snapping `gridStartDate` back to the first of the new month, which would
    /// make it impossible to swipe back to the previous month.
    @State private var isMonthChangeFromGridScroll: Bool = false
    
    private var monthName: String {
        CalendarHelper.monthName(for: currentMonthOffset)
    }
    
    // MARK: - Body
    
    var body: some View {
        // ScrollView with scrolling disabled gives us a reliable
        // top-anchored layout — content always starts at the top of the
        // safe area and any overflow at the bottom is simply clipped.
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                MonthPickerHeader(
                    currentMonthOffset: $currentMonthOffset,
                    showCalendar: $showCalendar,
                    showSettings: $showSettings
                )

                if showCalendar {
                    MonthCalendarView(
                        currentMonthOffset: $currentMonthOffset,
                        gridStartDate: $gridStartDate,
                        visibleGridDates: visibleGridDates,
                        onDateSelected: { selectedDate in
                            // Anchor `gridStartDate` earlier than the selected
                            // date so the user can still swipe LEFT in the
                            // time grid to see prior days. Without this the
                            // grid would be pinned at page 0 with nothing to
                            // its left.
                            let calendar = Calendar.current
                            let startOfToday = calendar.startOfDay(for: Date())
                            let selected = calendar.startOfDay(for: selectedDate)
                            let daysFromToday = calendar.dateComponents(
                                [.day], from: startOfToday, to: selected
                            ).day ?? 0

                            let newStartDate: Date
                            let pageIndex: Int

                            if daysFromToday >= 0 && daysFromToday < 30 {
                                // Selected date is within the 30-day window
                                // starting from today — anchor at today and
                                // jump to the page containing it.
                                newStartDate = startOfToday
                                pageIndex = daysFromToday / 3
                            } else {
                                // Selected date is far in the future — anchor
                                // a few pages before it so backward scrolling
                                // still has somewhere to go.
                                let bufferDays = 9 // 3 pages
                                newStartDate = calendar.date(
                                    byAdding: .day, value: -bufferDays, to: selected
                                ) ?? selected
                                pageIndex = bufferDays / 3
                            }

                            gridStartDate = newStartDate
                            gridCurrentPage = pageIndex
                            updateVisibleDates(from: newStartDate, page: pageIndex)
                        },
                        onDismiss: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showCalendar = false
                            }
                        }
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                } else if showSettings {
                    AvailabilitySettingsMenu()
                        .transition(.opacity)
                }

                Text("Mark when you're free")
                    .font(Constants.Fonts.body2)
                    .foregroundColor(Constants.Colors.secondaryGray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 28)

                AvailabilityGridView(
                    selectedCells: $selectedCells,
                    currentPage: $gridCurrentPage,
                    isEditing: true,
                    startDate: gridStartDate,
                    onVisibleDatesChanged: { dates in
                        visibleGridDates = dates

                        if let firstDate = dates.first {
                            let newMonthOffset = CalendarHelper.monthOffset(for: firstDate)
                            if newMonthOffset != currentMonthOffset && newMonthOffset >= 0 {
                                isMonthChangeFromGridScroll = true
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    currentMonthOffset = newMonthOffset
                                }
                            }
                        }
                    }
                )
                .id(gridStartDate) // Force rebuild when start date changes

                if !showCalendar {
                    PurpleButton(isLoading: isSaving, text: isSaving ? "Saving..." : "Save") {
                        Task {
                            await saveAvailability()
                        }
                    }
                    .disabled(isSaving)
                    .padding(.top, 16)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
        .scrollDisabled(true)
        .background(Constants.Colors.white)
        .overlay {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.7))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Constants.Colors.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Availability Settings")
                    .font(Constants.Fonts.h3)
                    .foregroundStyle(Constants.Colors.black)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    router.pop()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Constants.Colors.black)
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear {
            // Initialize visible dates
            updateVisibleDates(from: gridStartDate, page: 0)
            // Load availability from backend
            Task {
                await loadAvailability()
            }
        }
        .onChange(of: currentMonthOffset) { newOffset in
            // If the month changed because the grid was scrolled horizontally,
            // don't snap the grid back — the user is mid-scroll and we'd lose
            // the ability to scroll back to the previous month's dates.
            if isMonthChangeFromGridScroll {
                isMonthChangeFromGridScroll = false
                return
            }

            // Otherwise, the change came from the calendar (swipe or month picker)
            // and we should jump the grid to the first day of that month.
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
    
    // MARK: - Functions
    
    private func updateVisibleDates(from startDate: Date, page: Int) {
        let calendar = Calendar.current
        let startIndex = page * 3
        visibleGridDates = (0..<3).compactMap { offset in
            calendar.date(byAdding: .day, value: startIndex + offset, to: startDate)
        }
    }
    
    private func loadAvailability() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await NetworkManager.shared.getAvailability()
            let cells = scheduleToSelectedCells(response.availability.schedule)
            let scheduleDates = Set(response.availability.schedule.keys)
            await MainActor.run {
                selectedCells = cells
                knownScheduleDates = scheduleDates
            }
        } catch {
            print("Failed to load availability: \(error)")
        }
    }
    
    private func saveAvailability() async {
        isSaving = true
        defer { isSaving = false }
        
        let schedule = selectedCellsToSchedule(selectedCells)
        
        do {
            _ = try await NetworkManager.shared.updateAvailability(schedule: schedule)
            print("Successfully saved availability with \(schedule.count) days")
            // After a successful save, the new set of known dates is whatever
            // we just sent (excluding the explicit empty-array clears).
            await MainActor.run {
                knownScheduleDates = Set(schedule.compactMap { $0.value.isEmpty ? nil : $0.key })
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save availability: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Conversion Helpers
    
    /// Converts selected cells to API schedule format [DateKey: [AvailabilitySlot]]
    private func selectedCellsToSchedule(_ cells: Set<CellIdentifier>) -> [String: [AvailabilitySlot]] {
        let availabilities = AvailabilityGridView.cellsToAvailabilities(cells)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        // Seed the schedule with empty arrays for every date that previously
        // had availability on the backend. Any of these dates that the user
        // didn't re-select will stay as `[]`, signaling the backend to clear
        // them. Without this, clearing all cells would send `{}` which the
        // server merges (i.e., no-op) instead of treating as a wipe.
        var schedule: [String: [AvailabilitySlot]] = [:]
        for dateKey in knownScheduleDates {
            schedule[dateKey] = []
        }

        for availability in availabilities {
            let dateKey = dateFormatter.string(from: availability.startDate)
            let slot = AvailabilitySlot(startDate: availability.startDate, endDate: availability.endDate)

            if schedule[dateKey] != nil {
                schedule[dateKey]?.append(slot)
            } else {
                schedule[dateKey] = [slot]
            }
        }

        return schedule
    }
    
    /// Converts API schedule format to selected cells
    private func scheduleToSelectedCells(_ schedule: [String: [AvailabilitySlot]]) -> Set<CellIdentifier> {
        var cells = Set<CellIdentifier>()
        
        for (_, slots) in schedule {
            for slot in slots {
                // Convert AvailabilitySlot to local Availability and then to cells
                let availability = Availability(startDate: slot.startDate, endDate: slot.endDate)
                let cellsForSlot = AvailabilityGridView.availabilitiesToCells([availability])
                cells.formUnion(cellsForSlot)
            }
        }
        
        return cells
    }
}
