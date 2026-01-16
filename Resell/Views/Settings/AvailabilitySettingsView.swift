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
    @State private var showSettings: Bool = false
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
                showCalendar: $showCalendar,
                showSettings: $showSettings
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
                        // Explicitly set the start date (binding should handle this but being explicit)
                        gridStartDate = selectedDate
                        // Update visible dates immediately
                        updateVisibleDates(from: selectedDate, page: 0)
                    }
                )
                .padding(.horizontal)
                .padding(.vertical, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if showSettings {
                AvailabilitySettingsMenu()
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
            .id(gridStartDate) // Force rebuild when start date changes
            
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
        .onChange(of: currentMonthOffset) { newOffset in
            // When user swipes to change month on calendar, update grid to first day of that month
            let calendar = Calendar.current
            let today = Date()
            
            // Calculate the first day of the target month
            if let targetMonth = calendar.date(byAdding: .month, value: newOffset, to: today),
               let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: targetMonth)) {
                
                // If it's the current month, start from today; otherwise start from 1st of month
                let startOfToday = calendar.startOfDay(for: today)
                let newStartDate = (newOffset == 0 && firstOfMonth < startOfToday) ? startOfToday : firstOfMonth
                
                // Only update if the change came from calendar swipe (not from grid scroll)
                // We detect this by checking if current gridStartDate is NOT in the new month
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
