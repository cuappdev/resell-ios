//
//  AvailabilitySelectorView.swift
//  Resell
//
//  Created by Richie Sun on 11/30/24.
//

import FirebaseFirestore
import SwiftUI

struct AvailabilitySelectorView: View {

    // MARK: - Properties

    @State private var selectedCells: Set<CellIdentifier> = []
    @State private var draggedCells: Set<CellIdentifier> = []
    @State private var toggleSelectionMode: Bool? = nil
    @State private var currentPage: Int = 0
    @State private var isMovingForward: Bool = true
    @State private var isDraggingCells: Bool = false
    @State private var dragStartLocation: CGPoint = .zero

    @Binding var isPresented: Bool
    @Binding var selectedDates: [Availability]
    @Binding var didSubmit: Bool
    @Binding var isEditing: Bool

    var proposerName: String? = nil
    let dates: [String] = generateDates()
    let shortDates: [String] = generateShortDates()
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

    // MARK: - UI

    var body: some View {
        VStack(spacing: 16) {
            VStack {
                Text(isEditing ? "When are you free to meet?" : "\(proposerName ?? "")'s Availability")
                    .font(Constants.Fonts.title1)
                    .foregroundColor(Constants.Colors.black)
                    .padding(.top)

                Text(isEditing ? "Click and drag cells to select meeting times" : "Select a 30-minute block to propose a meeting.")
                    .font(Constants.Fonts.body2)
                    .foregroundColor(Constants.Colors.secondaryGray)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

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
                                }
                            } else if horizontalDrag > 50 || velocity > 100 {
                                // Swipe right - go to previous page
                                if currentPage > 0 {
                                    currentPage -= 1
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

            Spacer()

            PurpleButton(text: isEditing ? "Send" : "Propose", action: saveAvailability)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 32)
        .background(Constants.Colors.white)
        .onAppear(perform: initializeSelectedCells)
    }

    // MARK: - Helper Views
    
    private let timeColumnWidth: CGFloat = 90
    private let gridColumnWidth: CGFloat = UIScreen.width / 5 + 10
    private let lineExtension: CGFloat = 12 // Extra pixels beyond the grid
    private let headerHeight: CGFloat = 44
    private let verticalLineHeaderExtension: CGFloat = 42 // How far vertical lines extend into header
    
    private var totalGridWidth: CGFloat {
        timeColumnWidth + gridColumnWidth * 3 + lineExtension
    }
    
    private var totalVerticalLineHeight: CGFloat {
        CGFloat(times.count) * cellHeight + verticalLineHeaderExtension
    }
    
    private let scrollableGridHeight: CGFloat = UIScreen.height * 0.55
    
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
                            // Time labels column (scrollable area for vertical scroll)
                            VStack(spacing: 0) {
                                ForEach(times, id: \.self) { time in
                                    Text(time)
                                        .font(Constants.Fonts.title2)
                                        .foregroundStyle(Constants.Colors.secondaryGray)
                                        .frame(width: timeColumnWidth, height: cellHeight)
                                }
                            }

                            // Cells area - with scroll blocking overlay
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
                .frame(height: 35)
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
        // Offset for the time labels column (80 width) and header row (44 height)
        let headerHeight: CGFloat = 44 // header row only
        
        let adjustedX = location.x - timeColumnWidth
        let adjustedY = location.y - headerHeight
        
        guard adjustedX >= 0, adjustedY >= 0 else { return nil }
        
        let rowHeight = cellHeight

        // Column index: which date
        let col = Int(adjustedX / gridColumnWidth)
        guard col >= 0, col < dates.count else { return nil }

        // Row index: which time slot
        let row = Int(adjustedY / rowHeight)
        guard row >= 0, row < times.count else { return nil }

        let isTopHalf = adjustedY.truncatingRemainder(dividingBy: rowHeight) < rowHeight / 2
        let date = dates[col]
        let time = times[row]

        return CellIdentifier(date: date, time: isTopHalf ? "\(time) Top" : "\(time) Bottom")
    }


    private func initializeSelectedCells() {
        for block in selectedDates {
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
            selectedCells.insert(identifier)
        }
    }

    private func goToPreviousPage() {
        if currentPage > 0 {
            isMovingForward = false
            currentPage -= 1
        }
    }

    private func goToNextPage() {
        if currentPage < paginatedDates.count - 1 {
            isMovingForward = true
            currentPage += 1
        }
    }

    private func toggleCellSelection(date: String, time: String, isTopHalf: Bool) {
        let halfIdentifier = isTopHalf ? "\(time) Top" : "\(time) Bottom"
        let identifier = CellIdentifier(date: date, time: halfIdentifier)

        if selectedCells.contains(identifier) {
            selectedCells.remove(identifier)
        } else {
            selectedCells.insert(identifier)
        }
    }

    private func saveAvailability() {
        selectedDates = selectedCells.compactMap { createDate(from: $0.date, timeString: $0.time) }

        didSubmit = true
        isPresented = false
    }

    private func createDate(from dateString: String, timeString: String) -> Availability? {
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

// MARK: - CellView

struct CellView: View {

    let isSelectedTop: Bool
    let isSelectedBottom: Bool
    let isHighlightedTop: Bool
    let isHighlightedBottom: Bool

    private let cellHeight = UIScreen.height / 12 - 25
    private let cellWidth = UIScreen.width / 5 + 10

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

// MARK: - StrokeDashedLine

struct StrokeDashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
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

    let startHour = 8
    let endHour = 22
    return (startHour...endHour).map { hour in
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
}
