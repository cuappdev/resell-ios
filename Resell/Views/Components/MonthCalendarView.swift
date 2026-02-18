//
//  MonthCalendarView.swift
//  Resell
//
//  Created by Charles Liggins on 1/14/26.
//

import SwiftUI

// MARK: - Calendar Data Models

struct CalendarDay: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let dayNumber: Int
    let isCurrentMonth: Bool
    let isPast: Bool
    let isToday: Bool
    let weekdayIndex: Int // 0 = Sunday, 6 = Saturday
    let rowIndex: Int // Which row in the grid (0-4)
    
    var isSelectable: Bool {
        isCurrentMonth && !isPast
    }
}

struct CalendarMonthData {
    let monthName: String
    let year: Int
    let days: [CalendarDay]
    let referenceDate: Date // First day of the month
    
    static let weekdaySymbols = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
}

// MARK: - Calendar Helper Functions

struct CalendarHelper {
    
    /// Generates calendar data for a given month
    static func generateMonthData(monthOffset: Int = 0) -> CalendarMonthData {
        let calendar = Calendar.current
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        
        guard let targetMonth = calendar.date(byAdding: .month, value: monthOffset, to: today),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: targetMonth))
        else {
            return CalendarMonthData(monthName: "", year: 0, days: [], referenceDate: today)
        }
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM"
        let monthName = monthFormatter.string(from: firstOfMonth)
        let year = calendar.component(.year, from: firstOfMonth)
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        
        guard let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return CalendarMonthData(monthName: monthName, year: year, days: [], referenceDate: firstOfMonth)
        }
        let daysInMonth = range.count
        
        var days: [CalendarDay] = []
        var currentIndex = 0
        
        // Add leading days from previous month
        if firstWeekday > 0 {
            guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstOfMonth),
                  let prevMonthRange = calendar.range(of: .day, in: .month, for: previousMonth)
            else {
                return CalendarMonthData(monthName: monthName, year: year, days: [], referenceDate: firstOfMonth)
            }
            
            let prevMonthDays = prevMonthRange.count
            let startDay = prevMonthDays - firstWeekday + 1
            
            for day in startDay...prevMonthDays {
                if let date = calendar.date(byAdding: .day, value: day - prevMonthDays - 1, to: firstOfMonth) {
                    let dateStart = calendar.startOfDay(for: date)
                    days.append(CalendarDay(
                        date: date,
                        dayNumber: day,
                        isCurrentMonth: false,
                        isPast: dateStart < startOfToday,
                        isToday: false,
                        weekdayIndex: currentIndex % 7,
                        rowIndex: currentIndex / 7
                    ))
                    currentIndex += 1
                }
            }
        }
        
        // Add days of current month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                let dateStart = calendar.startOfDay(for: date)
                days.append(CalendarDay(
                    date: date,
                    dayNumber: day,
                    isCurrentMonth: true,
                    isPast: dateStart < startOfToday,
                    isToday: calendar.isDate(date, inSameDayAs: today),
                    weekdayIndex: currentIndex % 7,
                    rowIndex: currentIndex / 7
                ))
                currentIndex += 1
            }
        }
        
        // Add trailing days from next month to fill 35 slots
        let remainingSlots = 35 - days.count
        if remainingSlots > 0 {
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: firstOfMonth) else {
                return CalendarMonthData(monthName: monthName, year: year, days: days, referenceDate: firstOfMonth)
            }
            
            for day in 1...remainingSlots {
                if let date = calendar.date(byAdding: .day, value: day - 1, to: nextMonth) {
                    days.append(CalendarDay(
                        date: date,
                        dayNumber: day,
                        isCurrentMonth: false,
                        isPast: false,
                        isToday: false,
                        weekdayIndex: currentIndex % 7,
                        rowIndex: currentIndex / 7
                    ))
                    currentIndex += 1
                }
            }
        }
        
        return CalendarMonthData(
            monthName: monthName,
            year: year,
            days: Array(days.prefix(35)),
            referenceDate: firstOfMonth
        )
    }
    
    /// Gets the month name for a given offset
    static func monthName(for monthOffset: Int) -> String {
        let calendar = Calendar.current
        guard let targetMonth = calendar.date(byAdding: .month, value: monthOffset, to: Date()) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: targetMonth)
    }
    
    /// Converts a Date to the date string format used by AvailabilityGridView
    static func dateToGridFormat(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E \nMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    /// Gets dates for the availability grid starting from a selected date range
    static func generateGridDates(startingFrom date: Date, count: Int = 30) -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "E \nMMM d, yyyy"
        
        return (0..<count).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: date)
        }.map { formatter.string(from: $0) }
    }
    
    /// Gets short dates for grid headers starting from a date
    static func generateShortGridDates(startingFrom date: Date, count: Int = 30) -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d"
        
        return (0..<count).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: date)
        }.map { formatter.string(from: $0) }
    }
    
    /// Converts grid date strings back to Date objects
    static func gridDateStringToDate(_ dateString: String) -> Date? {
        let cleanDateString = dateString.replacingOccurrences(of: "\n", with: " ")
        let formatter = DateFormatter()
        formatter.dateFormat = "E MMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: cleanDateString)
    }
    
    /// Gets the month offset for a given date relative to today
    static func monthOffset(for date: Date) -> Int {
        let calendar = Calendar.current
        let today = Date()
        let todayComponents = calendar.dateComponents([.year, .month], from: today)
        let dateComponents = calendar.dateComponents([.year, .month], from: date)
        
        let yearDiff = (dateComponents.year ?? 0) - (todayComponents.year ?? 0)
        let monthDiff = (dateComponents.month ?? 0) - (todayComponents.month ?? 0)
        
        return yearDiff * 12 + monthDiff
    }
}

// MARK: - Month Calendar View

struct MonthCalendarView: View {
    @Binding var currentMonthOffset: Int
    
    /// The start date for the grid (first of the 3 visible dates)
    @Binding var gridStartDate: Date
    
    /// The three dates currently visible in the availability grid
    var visibleGridDates: [Date] = []
    
    /// Called when user taps a date to change the grid start
    var onDateSelected: ((Date) -> Void)?
    
    private var monthData: CalendarMonthData {
        CalendarHelper.generateMonthData(monthOffset: currentMonthOffset)
    }
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    private let cellHeight: CGFloat = 40
    private let rowSpacing: CGFloat = 8
    
    var body: some View {
        VStack(spacing: 12) {
            weekdayHeader
            
            // Calendar grid with selection overlay
            GeometryReader { geometry in
                let cellWidth = geometry.size.width / 7
                
                ZStack(alignment: .topLeading) {
                    // Selection background layer
                    selectionBackgroundLayer(cellWidth: cellWidth)
                    
                    // Day cells
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
                            withAnimation(.easeInOut(duration: 0.25)) {
                                currentMonthOffset += 1
                            }
                        } else if verticalDrag > 50 {
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
                    .font(Constants.Fonts.title2)
                    .foregroundStyle(Constants.Colors.secondaryGray)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Selection Background Layer
    
    private func selectionBackgroundLayer(cellWidth: CGFloat) -> some View {
        // Find visible days in this month's calendar
        let visibleDaysInMonth = monthData.days.filter { day in
            visibleGridDates.contains { Calendar.current.isDate($0, inSameDayAs: day.date) }
        }
        
        // Group by row
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
                        
                        // Determine corner rounding based on position in selection
                        let isFirstRow = rowIndex == sortedRowIndices.first
                        let isLastRow = rowIndex == sortedRowIndices.last
                        let continuesFromAbove = sortedRowIndices.contains(rowIndex - 1)
                        let continuesToBelow = sortedRowIndices.contains(rowIndex + 1)
                        
                        // Check if row above ended at Saturday (index 6)
                        let rowAboveEndedAtSaturday: Bool = {
                            if let aboveRow = rowGroups[rowIndex - 1] {
                                return aboveRow.contains { $0.weekdayIndex == 6 }
                            }
                            return false
                        }()
                        
                        // Check if this row starts at Sunday (index 0)
                        let startsAtSunday = firstDay.weekdayIndex == 0
                        let endsAtSaturday = lastDay.weekdayIndex == 6
                        
                        SelectionRowShape(
                            cornerRadius: 12,
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
            .font(Constants.Fonts.body1)
            .foregroundStyle(dayTextColor(for: day))
            .frame(maxWidth: .infinity)
            .frame(height: cellHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                guard day.isSelectable else { return }
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

// MARK: - Selection Row Shape

struct SelectionRowShape: Shape {
    let cornerRadius: CGFloat
    let roundTopLeft: Bool
    let roundTopRight: Bool
    let roundBottomLeft: Bool
    let roundBottomRight: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let tl = roundTopLeft ? cornerRadius : 0
        let tr = roundTopRight ? cornerRadius : 0
        let bl = roundBottomLeft ? cornerRadius : 0
        let br = roundBottomRight ? cornerRadius : 0
        
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        if tr > 0 {
            path.addArc(center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
                       radius: tr,
                       startAngle: .degrees(-90),
                       endAngle: .degrees(0),
                       clockwise: false)
        }
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        if br > 0 {
            path.addArc(center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
                       radius: br,
                       startAngle: .degrees(0),
                       endAngle: .degrees(90),
                       clockwise: false)
        }
        
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        if bl > 0 {
            path.addArc(center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
                       radius: bl,
                       startAngle: .degrees(90),
                       endAngle: .degrees(180),
                       clockwise: false)
        }
        
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        if tl > 0 {
            path.addArc(center: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
                       radius: tl,
                       startAngle: .degrees(180),
                       endAngle: .degrees(270),
                       clockwise: false)
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Month Picker Header

struct MonthPickerHeader: View {
    @Binding var currentMonthOffset: Int
    @Binding var showCalendar: Bool
    @Binding var showSettings: Bool
    
    private var monthName: String {
        CalendarHelper.monthName(for: currentMonthOffset)
    }
    
    var body: some View {
        HStack(spacing: 16) {
//            Button {
//                showSettings.toggle()
//                $showCalendar.wrappedValue = false
//            } label: {
//                Image(systemName: "line.3.horizontal")
//                    .font(.title2)
//                    .foregroundStyle(Constants.Colors.black)
//            }
            
            Button {
                showCalendar.toggle()
                $showSettings.wrappedValue = false
            } label: {
                ZStack {
                    if showCalendar {
                        RoundedRectangle(cornerRadius: 8)
                            .frame(width: 116, height: 28)
                            .foregroundStyle(Constants.Colors.secondaryGray.opacity(0.25))
                    }
                    
                    Text(monthName)
                        .font(Constants.Fonts.h2)
                        .foregroundStyle(Constants.Colors.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .gesture(
                            DragGesture()
                                .onEnded { value in
                                    if value.translation.width < -50 {
                                        withAnimation { currentMonthOffset += 1 }
                                    } else if value.translation.width > 50 {
                                        if currentMonthOffset > 0 {
                                            withAnimation { currentMonthOffset -= 1 }
                                        }
                                    }
                                }
                        )
                }
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}
