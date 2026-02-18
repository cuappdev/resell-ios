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
    
    private var monthName: String {
        CalendarHelper.monthName(for: currentMonthOffset)
    }
    
    // MARK: - Body
    
    var body: some View {
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
                        gridCurrentPage = 0
                        gridStartDate = selectedDate
                        updateVisibleDates(from: selectedDate, page: 0)
                    }
                )
                .padding(.horizontal)
                .padding(.vertical, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if showSettings {
                AvailabilitySettingsMenu()
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
        .scrollDisabled(!showCalendar)
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
    
    private func loadAvailability() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await NetworkManager.shared.getAvailability()
            let cells = scheduleToSelectedCells(response.availability.schedule)
            await MainActor.run {
                selectedCells = cells
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
        
        // Group availabilities by date
        var schedule: [String: [AvailabilitySlot]] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
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
