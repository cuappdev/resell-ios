//
//  AvailabilityGridView.swift
//  Resell
//
//  Created by Richie Sun on 11/30/24.
//

import SwiftUI

struct AvailabilityGridView: View {

    // MARK: - Properties

    @Binding var selectedCells: Set<CellIdentifier>
    
    /// Binding for current page - allows parent to track which dates are visible
    @Binding var currentPage: Int
    
    @State private var draggedCells: Set<CellIdentifier> = []
    @State private var toggleSelectionMode: Bool? = nil
    @State private var isDraggingCells: Bool = false
    @State private var dragStartLocation: CGPoint = .zero

    /// Whether the user can edit (drag to select) cells
    var isEditing: Bool = true
    
    /// Optional start date for the grid. If nil, starts from today.
    var startDate: Date? = nil
    
    /// Optional custom height for the scrollable grid area. If nil, uses default (65% of screen).
    var gridHeight: CGFloat? = nil
    
    /// Called when the visible dates change (page swipe)
    var onVisibleDatesChanged: (([Date]) -> Void)?
    
    private var dates: [String] {
        if let start = startDate {
            return CalendarHelper.generateGridDates(startingFrom: start)
        }
        return generateDates()
    }
    
    private var shortDates: [String] {
        if let start = startDate {
            return CalendarHelper.generateShortGridDates(startingFrom: start)
        }
        return generateShortDates()
    }
    
    let times: [String] = generateTimes()

    private var paginatedDates: [ArraySlice<String>] {
        stride(from: 0, to: dates.count, by: 3).map {
            dates[$0..<min($0 + 3, dates.count)]
        }
    }
    
    private var paginatedShortDates: [ArraySlice<String>] {
        stride(from: 0, to: shortDates.count, by: 3).map {
            shortDates[$0..<min($0 + 3, shortDates.count)]
        }
    }

    private let cellHeight = UIScreen.height / 12 - 25
    
    /// Returns the Date objects for the currently visible 3 columns
    var visibleDates: [Date] {
        guard currentPage >= 0 && currentPage < paginatedDates.count else { return [] }
        return Array(paginatedDates[currentPage]).compactMap { CalendarHelper.gridDateStringToDate($0) }
    }

    // MARK: - UI

    var body: some View {
        ZStack {
            ForEach(Array(paginatedDates.indices), id: \.self) { index in
                pageView(for: index)
                    .offset(x: CGFloat(index - currentPage) * UIScreen.width)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
        .simultaneousGesture(
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    if dragStartLocation == .zero {
                        dragStartLocation = value.startLocation
                    }
                    
                    // Only handle cell selection if drag started in the cell area (after timeColumnWidth)
                    let startedInCellArea = dragStartLocation.x > timeColumnWidth
                    
                    if startedInCellArea && isEditing {
                        let horizontalDrag = abs(value.translation.width)
                        let verticalDrag = abs(value.translation.height)
                        
                        // Determine drag direction at the start - prefer vertical for cell selection
                        if !isDraggingCells && verticalDrag > 10 && horizontalDrag < 50 {
                            isDraggingCells = true
                        }
                        
                        if isDraggingCells {
                            // Handle cell selection
                            if let identifier = mapDragLocationToCell(
                                location: value.location,
                                dates: Array(paginatedDates[currentPage]),
                                times: times,
                                cellHeight: cellHeight
                            ) {
                                if toggleSelectionMode == nil {
                                    toggleSelectionMode = selectedCells.contains(identifier) ? false : true
                                }
                                draggedCells.insert(identifier)
                            }
                        }
                    }
                }
                .onEnded { value in
                    let startedInCellArea = dragStartLocation.x > timeColumnWidth
                    
                    if isDraggingCells && startedInCellArea {
                        // Finalize cell selection
                        if let toggleSelectionMode = toggleSelectionMode {
                            if toggleSelectionMode {
                                selectedCells.formUnion(draggedCells)
                            } else {
                                selectedCells.subtract(draggedCells)
                            }
                        }
                    } else if !isDraggingCells {
                        // Handle horizontal swipe for page navigation
                        let horizontalDrag = value.translation.width
                        let velocity = value.predictedEndTranslation.width - value.translation.width
                        
                        if horizontalDrag < -50 || velocity < -100 {
                            // Swipe left - go to next page
                            if currentPage < paginatedDates.count - 1 {
                                currentPage += 1
                                notifyVisibleDatesChanged()
                            }
                        } else if horizontalDrag > 50 || velocity > 100 {
                            // Swipe right - go to previous page
                            if currentPage > 0 {
                                currentPage -= 1
                                notifyVisibleDatesChanged()
                            }
                        }
                    }
                    
                    // Reset state
                    draggedCells.removeAll()
                    toggleSelectionMode = nil
                    isDraggingCells = false
                    dragStartLocation = .zero
                }
        )
        .onAppear {
            notifyVisibleDatesChanged()
        }
        .onChange(of: startDate) { _ in
            notifyVisibleDatesChanged()
        }
    }
    
    private func notifyVisibleDatesChanged() {
        let dates = visibleDates
        onVisibleDatesChanged?(dates)
    }

    // MARK: - Helper Views
    
    private let timeColumnWidth: CGFloat = 90
    private let gridColumnWidth: CGFloat = UIScreen.width / 5 + 10
    private let lineExtension: CGFloat = 12
    private let headerHeight: CGFloat = 44
    
    private var totalGridWidth: CGFloat {
        timeColumnWidth + gridColumnWidth * 3 + lineExtension
    }
    
    private var scrollableGridHeight: CGFloat {
        gridHeight ?? UIScreen.height * 0.65
    }
    
    private func pageView(for index: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sticky header row with EST and dates + vertical lines
            ZStack(alignment: .topLeading) {
                // Vertical lines in header
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: timeColumnWidth, height: headerHeight)
                    
                    ForEach(0..<4, id: \.self) { colIndex in
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 0.5, height: headerHeight)
                        
                        if colIndex < 3 {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: gridColumnWidth - 0.5, height: headerHeight)
                        }
                    }
                }
                
                // Header text
                HStack(spacing: 0) {
                    Text("EST")
                        .font(Constants.Fonts.title2)
                        .foregroundStyle(Constants.Colors.secondaryGray)
                        .frame(width: timeColumnWidth, height: headerHeight)
                    
                    ForEach(Array(paginatedShortDates[index]), id: \.self) { shortDate in
                        Text(shortDate)
                            .font(Constants.Fonts.title2)
                            .foregroundStyle(Constants.Colors.secondaryGray)
                            .frame(width: gridColumnWidth, height: headerHeight)
                    }
                }
            }
            .background(Constants.Colors.white)
            
            // Scrollable grid area with fade effect
            ZStack(alignment: .bottom) {
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Vertical grid lines in scroll area
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: timeColumnWidth)
                            
                            ForEach(0..<4, id: \.self) { colIndex in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 0.5, height: CGFloat(times.count) * cellHeight)
                                
                                if colIndex < 3 {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(width: gridColumnWidth - 0.5)
                                }
                            }
                        }
                        
                        // Horizontal grid lines
                        VStack(spacing: 0) {
                            ForEach(0..<times.count + 1, id: \.self) { rowIndex in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: totalGridWidth, height: 0.5)
                                
                                if rowIndex < times.count {
                                    Spacer()
                                        .frame(height: cellHeight - 0.5)
                                }
                            }
                        }
                        
                        // Time labels and cells
                        HStack(spacing: 0) {
                            // Time labels column
                            VStack(spacing: 0) {
                                ForEach(times, id: \.self) { time in
                                    Text(time)
                                        .font(Constants.Fonts.title2)
                                        .foregroundStyle(Constants.Colors.secondaryGray)
                                        .frame(width: timeColumnWidth, height: cellHeight)
                                }
                            }

                            // Cells area
                            HStack(spacing: 0) {
                                ForEach(Array(zip(paginatedDates[index], paginatedShortDates[index])), id: \.0) { date, _ in
                                    VStack(spacing: 0) {
                                        ForEach(times, id: \.self) { time in
                                            CellView(
                                                isSelectedTop: selectedCells.contains(CellIdentifier(date: date, time: "\(time) Top")),
                                                isSelectedBottom: selectedCells.contains(CellIdentifier(date: date, time: "\(time) Bottom")),
                                                isHighlightedTop: draggedCells.contains(CellIdentifier(date: date, time: "\(time) Top")),
                                                isHighlightedBottom: draggedCells.contains(CellIdentifier(date: date, time: "\(time) Bottom"))
                                            )
                                            .frame(width: gridColumnWidth, height: cellHeight)
                                        }
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { _ in }
                                    .onEnded { _ in }
                            )
                        }
                    }
                }
                .frame(height: scrollableGridHeight)
                .clipped()
                
                // Fade effect at bottom
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 25)
                .allowsHitTesting(false)
            }
        }
        .frame(width: UIScreen.width - 32)
        .contentShape(Rectangle())
    }

    // MARK: - Functions
    
    private func mapDragLocationToCell(
        location: CGPoint,
        dates: [String],
        times: [String],
        cellHeight: CGFloat
    ) -> CellIdentifier? {
        let headerHeight: CGFloat = 44
        
        let adjustedX = location.x - timeColumnWidth
        let adjustedY = location.y - headerHeight
        
        guard adjustedX >= 0, adjustedY >= 0 else { return nil }
        
        let rowHeight = cellHeight

        let col = Int(adjustedX / gridColumnWidth)
        guard col >= 0, col < dates.count else { return nil }

        let row = Int(adjustedY / rowHeight)
        guard row >= 0, row < times.count else { return nil }

        let isTopHalf = adjustedY.truncatingRemainder(dividingBy: rowHeight) < rowHeight / 2
        let date = dates[col]
        let time = times[row]

        return CellIdentifier(date: date, time: isTopHalf ? "\(time) Top" : "\(time) Bottom")
    }
}

// MARK: - CellView

struct CellView: View {

    let isSelectedTop: Bool
    let isSelectedBottom: Bool
    let isHighlightedTop: Bool
    let isHighlightedBottom: Bool

    private let cellHeight = UIScreen.height / 12 - 25

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(isHighlightedTop
                      ? (isSelectedTop ? Constants.Colors.resellPurple.opacity(0.3) : Constants.Colors.resellPurple.opacity(0.5))
                      : (isSelectedTop ? Constants.Colors.resellPurple : Color.clear))
                .frame(height: cellHeight / 2)

            Rectangle()
                .fill(isHighlightedBottom
                      ? (isSelectedBottom ? Constants.Colors.resellPurple.opacity(0.3) : Constants.Colors.resellPurple.opacity(0.5))
                      : (isSelectedBottom ? Constants.Colors.resellPurple : Color.clear))
                .frame(height: cellHeight / 2)
        }
    }
}

// MARK: - CellIdentifier

struct CellIdentifier: Hashable {
    let date: String
    let time: String
}

// MARK: - Helper Functions

func generateDates() -> [String] {
    let formatter = DateFormatter()
    formatter.dateFormat = "E \nMMM d, yyyy"

    return (0..<30).compactMap {
        Calendar.current.date(byAdding: .day, value: $0, to: Date())
    }.map { formatter.string(from: $0) }
}

func generateShortDates() -> [String] {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE d"

    return (0..<30).compactMap {
        Calendar.current.date(byAdding: .day, value: $0, to: Date())
    }.map { formatter.string(from: $0) }
}

func generateTimes() -> [String] {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"

    let startHour = 8
    let endHour = 22
    return (startHour...endHour).map { hour in
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
}

// MARK: - Availability Conversion Helpers

extension AvailabilityGridView {
    
    /// Converts selected cells to Availability objects
    static func cellsToAvailabilities(_ cells: Set<CellIdentifier>) -> [Availability] {
        cells.compactMap { createAvailability(from: $0.date, timeString: $0.time) }
    }
    
    /// Converts Availability objects to cell identifiers
    static func availabilitiesToCells(_ availabilities: [Availability]) -> Set<CellIdentifier> {
        var cells = Set<CellIdentifier>()
        
        for block in availabilities {
            let startDate = block.startDate

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E \nMMM d, yyyy"
            let dateString = dateFormatter.string(from: startDate)

            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "h:mm a"

            let calendar = Calendar.current
            let minute = calendar.component(.minute, from: startDate)
            let isTopHalf = (minute != 30)

            let adjustedTime = isTopHalf ? startDate : startDate.adding(minutes: -30)
            let timeString = timeFormatter.string(from: adjustedTime)

            let halfIdentifier = isTopHalf ? "\(timeString) Top" : "\(timeString) Bottom"
            let identifier = CellIdentifier(date: dateString, time: halfIdentifier)
            cells.insert(identifier)
        }
        
        return cells
    }
    
    private static func createAvailability(from dateString: String, timeString: String) -> Availability? {
        let cleanDateString = dateString.replacingOccurrences(of: "\n", with: " ")
        let cleanTimeString = timeString.replacingOccurrences(of: " Top", with: "").replacingOccurrences(of: " Bottom", with: "")

        let combinedString = "\(cleanDateString) \(cleanTimeString)"

        let formatter = DateFormatter()
        formatter.dateFormat = "E MMM d, yyyy h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current

        if var parsedDate = formatter.date(from: combinedString) {
            if timeString.contains("Bottom") {
                parsedDate = parsedDate.adding(minutes: 30)
            }

            return Availability(startDate: parsedDate, endDate: parsedDate.adding(minutes: 30))
        } else {
            return nil
        }
    }
}
