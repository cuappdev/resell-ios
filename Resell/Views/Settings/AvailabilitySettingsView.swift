//
//  AvailabilitySettingsView.swift
//  Resell
//
//  Created by Charles Liggins on 1/12/26.
//

import SwiftUI

struct AvailabilitySettingsView: View {
    // MARK: - Properties
    
    @State private var selectedCells: Set<CellIdentifier> = []
    @State private var currentMonthOffset: Int = 0
    @State private var gridStartDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showCalendar: Bool = false
    @State private var gridCurrentPage: Int = 0
    @State private var visibleGridDates: [Date] = []
    
    private var monthName: String {
        CalendarHelper.monthName(for: currentMonthOffset)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Month picker header with hamburger menu - stays fixed at top
            MonthPickerHeader(
                currentMonthOffset: $currentMonthOffset,
                onMenuTap: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showCalendar.toggle()
                    }
                }
            )
            .padding(.top, 8)
            
            // Month calendar - collapsible
            if showCalendar {
                MonthCalendarView(
                    currentMonthOffset: $currentMonthOffset,
                    gridStartDate: $gridStartDate,
                    visibleGridDates: visibleGridDates,
                    onDateSelected: { selectedDate in
                        // Reset page to 0 when user taps a date
                        gridCurrentPage = 0
                        // Update visible dates immediately
                        updateVisibleDates(from: selectedDate, page: 0)
                    }
                )
                .padding(.horizontal)
                .padding(.vertical, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Availability grid - synced with calendar selection
            AvailabilityGridView(
                selectedCells: $selectedCells,
                currentPage: $gridCurrentPage,
                isEditing: true,
                startDate: gridStartDate,
                gridHeight: showCalendar ? UIScreen.height * 0.4 : UIScreen.height * 0.65,
                onVisibleDatesChanged: { dates in
                    visibleGridDates = dates
                    // Update month offset based on visible dates
                    if let firstDate = dates.first {
                        let newMonthOffset = CalendarHelper.monthOffset(for: firstDate)
                        if newMonthOffset != currentMonthOffset && newMonthOffset >= 0 {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentMonthOffset = newMonthOffset
                            }
                        }
                    }
                }
            )
            
            // Save button
            if !showCalendar {
                PurpleButton(text: "Save") {
                    saveAvailability()
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .background(Constants.Colors.white)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Availability")
                    .font(Constants.Fonts.h3)
                    .foregroundStyle(Constants.Colors.black)
            }
        }
        .onAppear {
            // Initialize visible dates
            updateVisibleDates(from: gridStartDate, page: 0)
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
    
    private func saveAvailability() {
        let availabilities = AvailabilityGridView.cellsToAvailabilities(selectedCells)
        // TODO: Save availabilities to backend/user profile
        print("Saving \(availabilities.count) availability slots")
    }
}

#Preview {
    NavigationStack {
        AvailabilitySettingsView()
    }
}
