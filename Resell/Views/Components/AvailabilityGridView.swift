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
    @State private var dragStartDate: String? = nil  // Track which day the drag started on
    @State private var lastDraggedCell: CellIdentifier? = nil  // Track last cell to fill gaps

    /// Whether the user can edit (drag to select) cells
    var isEditing: Bool = true
    
    /// When true, only one cell can be selected at a time (tapping a new cell deselects the previous one)
    var singleSelectionMode: Bool = false
    
    /// Optional start date for the grid. If nil, starts from today.
    var startDate: Date? = nil
    
    
    /// Called when the visible dates change (page swipe)
    var onVisibleDatesChanged: (([Date]) -> Void)?
    
    /// Cells where the buyer is unavailable (shown as light gray)
    var buyerUnavailableCells: Set<CellIdentifier> = []
    
    /// Cells where the seller is unavailable (shown as darker gray)
    var sellerUnavailableCells: Set<CellIdentifier> = []
    
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
            DragGesture(minimumDistance: singleSelectionMode ? 0 : 5)
                .onChanged { value in
                    if dragStartLocation == .zero {
                        dragStartLocation = value.startLocation
                    }
                    
                    let startedInCellArea = dragStartLocation.x > timeColumnWidth
                    
                    if startedInCellArea && isEditing {
                        if singleSelectionMode {
                            if let identifier = mapDragLocationToCell(
                                location: value.startLocation,
                                dates: Array(paginatedDates[currentPage]),
                                times: times,
                                cellHeight: cellHeight
                            ) {
                                if selectedCells.contains(identifier) {
                                    selectedCells.remove(identifier)
                                } else {
                                    selectedCells.removeAll()
                                    selectedCells.insert(identifier)
                                }
                            }
                            return
                        }
                        
                        let horizontalDrag = abs(value.translation.width)
                        let verticalDrag = abs(value.translation.height)
                        
                        if !isDraggingCells && verticalDrag > 10 && horizontalDrag < 50 {
                            isDraggingCells = true
                        }
                        
                        if isDraggingCells {
                            if let identifier = mapDragLocationToCell(
                                location: value.location,
                                dates: Array(paginatedDates[currentPage]),
                                times: times,
                                cellHeight: cellHeight
                            ) {
                                if dragStartDate == nil {
                                    dragStartDate = identifier.date
                                }
                                
                                guard identifier.date == dragStartDate else { return }
                                
                                if toggleSelectionMode == nil {
                                    toggleSelectionMode = selectedCells.contains(identifier) ? false : true
                                }
                                
                                if let lastCell = lastDraggedCell, lastCell.date == identifier.date {
                                    let filledCells = fillCellGap(from: lastCell, to: identifier, date: identifier.date)
                                    for cell in filledCells {
                                        draggedCells.insert(cell)
                                    }
                                }
                                
                                draggedCells.insert(identifier)
                                lastDraggedCell = identifier
                            }
                        }
                    }
                }
                .onEnded { value in
                    if singleSelectionMode {
                        dragStartLocation = .zero
                        return
                    }
                    
                    let startedInCellArea = dragStartLocation.x > timeColumnWidth
                    
                    if isDraggingCells && startedInCellArea {
                        if let toggleSelectionMode = toggleSelectionMode {
                            if toggleSelectionMode {
                                selectedCells.formUnion(draggedCells)
                            } else {
                                selectedCells.subtract(draggedCells)
                            }
                        }
                    } else if !isDraggingCells {
                        let horizontalDrag = value.translation.width
                        let velocity = value.predictedEndTranslation.width - value.translation.width
                        
                        if horizontalDrag < -50 || velocity < -100 {
                            if currentPage < paginatedDates.count - 1 {
                                currentPage += 1
                                notifyVisibleDatesChanged()
                            }
                        } else if horizontalDrag > 50 || velocity > 100 {
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
                    dragStartDate = nil
                    lastDraggedCell = nil
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
    
    private func pageView(for index: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
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
            
            // Grid area (non-scrollable)
            ZStack(alignment: .topLeading) {
                // Vertical grid lines
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
                    CellsGridView(
                        dates: Array(paginatedDates[index]),
                        times: times,
                        selectedCells: selectedCells,
                        draggedCells: draggedCells,
                        buyerUnavailableCells: buyerUnavailableCells,
                        sellerUnavailableCells: sellerUnavailableCells,
                        gridColumnWidth: gridColumnWidth,
                        cellHeight: cellHeight
                    )
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(width: UIScreen.width - 32)
        .contentShape(Rectangle())
    }

    // MARK: - Functions
    
    /// Fills in the cells between two cells in the same column to prevent gaps when dragging quickly
    private func fillCellGap(from startCell: CellIdentifier, to endCell: CellIdentifier, date: String) -> [CellIdentifier] {
        guard startCell.date == endCell.date else { return [] }
        
        // Find indices of the start and end cells
        guard let startTimeIndex = findTimeIndex(for: startCell.time),
              let endTimeIndex = findTimeIndex(for: endCell.time) else {
            return []
        }
        
        var filledCells: [CellIdentifier] = []
        
        // Determine direction (up or down)
        let minIndex = min(startTimeIndex, endTimeIndex)
        let maxIndex = max(startTimeIndex, endTimeIndex)
        
        // Fill in all cells between min and max
        for index in minIndex...maxIndex {
            let time = times[index]
            filledCells.append(CellIdentifier(date: date, time: "\(time) Top"))
            filledCells.append(CellIdentifier(date: date, time: "\(time) Bottom"))
        }
        
        return filledCells
    }
    
    /// Finds the time index for a given time string (handles "Top" and "Bottom" suffixes)
    private func findTimeIndex(for timeString: String) -> Int? {
        let cleanTime = timeString
            .replacingOccurrences(of: " Top", with: "")
            .replacingOccurrences(of: " Bottom", with: "")
        return times.firstIndex(of: cleanTime)
    }
    
    
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

// MARK: - CellsGridView

/// Optimized grid view that computes combinedCells once per render
struct CellsGridView: View {
    let dates: [String]
    let times: [String]
    let selectedCells: Set<CellIdentifier>
    let draggedCells: Set<CellIdentifier>
    let buyerUnavailableCells: Set<CellIdentifier>
    let sellerUnavailableCells: Set<CellIdentifier>
    let gridColumnWidth: CGFloat
    let cellHeight: CGFloat
    
    // Compute combined cells once for the entire grid
    private var combinedCells: Set<CellIdentifier> {
        selectedCells.union(draggedCells)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(dates.indices, id: \.self) { colIndex in
                let date = dates[colIndex]
                VStack(spacing: 0) {
                    ForEach(times.indices, id: \.self) { rowIndex in
                        let time = times[rowIndex]
                        cellView(date: date, time: time, rowIndex: rowIndex)
                            .frame(width: gridColumnWidth, height: cellHeight)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func cellView(date: String, time: String, rowIndex: Int) -> some View {
        let topIdentifier = CellIdentifier(date: date, time: "\(time) Top")
        let bottomIdentifier = CellIdentifier(date: date, time: "\(time) Bottom")
        
        let isSelectedTop = selectedCells.contains(topIdentifier)
        let isSelectedBottom = selectedCells.contains(bottomIdentifier)
        
        CellView(
            isSelectedTop: isSelectedTop,
            isSelectedBottom: isSelectedBottom,
            isHighlightedTop: draggedCells.contains(topIdentifier),
            isHighlightedBottom: draggedCells.contains(bottomIdentifier),
            isTopAdjacentSelected: checkTopAdjacent(date: date, rowIndex: rowIndex),
            isBottomAdjacentSelected: checkBottomAdjacent(date: date, rowIndex: rowIndex),
            isBuyerUnavailableTop: buyerUnavailableCells.contains(topIdentifier),
            isBuyerUnavailableBottom: buyerUnavailableCells.contains(bottomIdentifier),
            isSellerUnavailableTop: sellerUnavailableCells.contains(topIdentifier),
            isSellerUnavailableBottom: sellerUnavailableCells.contains(bottomIdentifier)
        )
    }
    
    private func checkTopAdjacent(date: String, rowIndex: Int) -> Bool {
        guard rowIndex > 0 else { return false }
        let adjacentTime = times[rowIndex - 1]
        let adjacentIdentifier = CellIdentifier(date: date, time: "\(adjacentTime) Bottom")
        return combinedCells.contains(adjacentIdentifier)
    }
    
    private func checkBottomAdjacent(date: String, rowIndex: Int) -> Bool {
        guard rowIndex < times.count - 1 else { return false }
        let adjacentTime = times[rowIndex + 1]
        let adjacentIdentifier = CellIdentifier(date: date, time: "\(adjacentTime) Top")
        return combinedCells.contains(adjacentIdentifier)
    }
}

// MARK: - CellView

struct CellView: View {

    let isSelectedTop: Bool
    let isSelectedBottom: Bool
    let isHighlightedTop: Bool
    let isHighlightedBottom: Bool
    
    // Adjacency information for smart borders (vertical only)
    let isTopAdjacentSelected: Bool
    let isBottomAdjacentSelected: Bool
    
    // Unavailability information
    var isBuyerUnavailableTop: Bool = false
    var isBuyerUnavailableBottom: Bool = false
    var isSellerUnavailableTop: Bool = false
    var isSellerUnavailableBottom: Bool = false

    private let cellHeight = UIScreen.height / 12 - 25
    
    // Opacity constants
    private let dragOpacity: CGFloat = 0.4
    private let selectedOpacity: CGFloat = 0.6
    
    // Unavailability colors
    private let buyerUnavailableColor = Color.gray.opacity(0.25)
    private let sellerUnavailableColor = Color.gray.opacity(0.45)
    
    // Border constants
    private let borderWidth: CGFloat = 2
    private let dashPattern: [CGFloat] = [4, 4]

    var body: some View {
        VStack(spacing: 0) {
            // Top half
            HalfCellView(
                isSelected: isSelectedTop,
                isHighlighted: isHighlightedTop,
                showTopBorder: isSelectedTop && !isTopAdjacentSelected,
                showBottomBorder: isSelectedTop && !isSelectedBottom,
                showLeftBorder: isSelectedTop,  // Always show left border
                showRightBorder: isSelectedTop,  // Always show right border
                fillColor: fillColor(isSelected: isSelectedTop, isHighlighted: isHighlightedTop, isBuyerUnavailable: isBuyerUnavailableTop, isSellerUnavailable: isSellerUnavailableTop),
                borderWidth: borderWidth,
                dashPattern: dashPattern
            )
            .frame(height: cellHeight / 2)

            // Bottom half
            HalfCellView(
                isSelected: isSelectedBottom,
                isHighlighted: isHighlightedBottom,
                showTopBorder: isSelectedBottom && !isSelectedTop,
                showBottomBorder: isSelectedBottom && !isBottomAdjacentSelected,
                showLeftBorder: isSelectedBottom,  // Always show left border
                showRightBorder: isSelectedBottom,  // Always show right border
                fillColor: fillColor(isSelected: isSelectedBottom, isHighlighted: isHighlightedBottom, isBuyerUnavailable: isBuyerUnavailableBottom, isSellerUnavailable: isSellerUnavailableBottom),
                borderWidth: borderWidth,
                dashPattern: dashPattern
            )
            .frame(height: cellHeight / 2)
        }
    }
    
    private func fillColor(isSelected: Bool, isHighlighted: Bool, isBuyerUnavailable: Bool, isSellerUnavailable: Bool) -> Color {
        if isHighlighted {
            // Currently being dragged - use lighter opacity
            return Constants.Colors.resellPurple.opacity(dragOpacity)
        } else if isSelected {
            // Finally selected - use darker opacity
            return Constants.Colors.resellPurple.opacity(selectedOpacity)
        } else if isSellerUnavailable {
            // Seller unavailable - darker gray (takes priority)
            return sellerUnavailableColor
        } else if isBuyerUnavailable {
            // Buyer unavailable - lighter gray
            return buyerUnavailableColor
        } else {
            // Not selected and available
            return .clear
        }
    }
}

// MARK: - HalfCellView

struct HalfCellView: View {
    let isSelected: Bool
    let isHighlighted: Bool
    let showTopBorder: Bool
    let showBottomBorder: Bool
    let showLeftBorder: Bool
    let showRightBorder: Bool
    let fillColor: Color
    let borderWidth: CGFloat
    let dashPattern: [CGFloat]
    
    var body: some View {
        ZStack {
            // Fill
            Rectangle()
                .fill(fillColor)
            
            // Dotted borders (only show if cell is selected or highlighted)
            if isSelected || isHighlighted {
                DottedBorderShape(
                    showTop: showTopBorder,
                    showBottom: showBottomBorder,
                    showLeft: showLeftBorder,
                    showRight: showRightBorder,
                    dashPattern: dashPattern
                )
                .stroke(Constants.Colors.resellPurple, style: StrokeStyle(lineWidth: borderWidth, dash: dashPattern))
            }
        }
    }
}

// MARK: - DottedBorderShape

struct DottedBorderShape: Shape {
    let showTop: Bool
    let showBottom: Bool
    let showLeft: Bool
    let showRight: Bool
    let dashPattern: [CGFloat]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        if showTop {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        
        if showBottom {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        
        if showLeft {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }
        
        if showRight {
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        
        return path
    }
}

// MARK: - CellIdentifier

struct CellIdentifier: Hashable, Equatable {
    let date: String
    let time: String
    
    // Custom hash function for better performance
    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(time)
    }
    
    static func == (lhs: CellIdentifier, rhs: CellIdentifier) -> Bool {
        lhs.date == rhs.date && lhs.time == rhs.time
    }
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

    let startHour = 10
    let endHour = 20
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
