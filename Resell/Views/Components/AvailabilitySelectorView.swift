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

    @Binding var isPresented: Bool
    @Binding var selectedDates: [AvailabilityBlock]
    @Binding var didSubmit: Bool

    let dates: [String] = generateDates()
    let times: [String] = generateTimes()

    private var paginatedDates: [ArraySlice<String>] {
        stride(from: 0, to: dates.count, by: 3).map {
            dates[$0..<min($0 + 3, dates.count)]
        }
    }

    // MARK: - UI

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: goToPreviousPage) {
                    Image(systemName: "chevron.left")
                        .font(Constants.Fonts.h1)
                        .foregroundColor(currentPage > 0 ? .black : .gray)
                }
                .disabled(currentPage == 0)

                Spacer()

                VStack {
                    Text("When are you free to meet?")
                        .font(Constants.Fonts.title2)
                        .foregroundColor(Constants.Colors.black)
                        .padding(.top)

                    Text("Click and drag cells to select meeting times")
                        .font(Constants.Fonts.body2)
                        .foregroundColor(Constants.Colors.secondaryGray)
                }

                Spacer()

                Button(action: goToNextPage) {
                    Image(systemName: "chevron.right")
                        .font(Constants.Fonts.h1)
                        .foregroundColor(currentPage < paginatedDates.count - 1 ? .black : .gray)
                }
                .disabled(currentPage >= paginatedDates.count - 1)
            }

            Spacer()

            ZStack {
                ForEach(Array(paginatedDates.indices), id: \.self) { index in
                    HStack(spacing: 0) {
                        VStack(spacing: 0) {
                            ForEach(times, id: \.self) { time in
                                VStack {
                                    Text(time)
                                        .font(Constants.Fonts.title4)
                                        .foregroundStyle(Constants.Colors.secondaryGray)
                                        .multilineTextAlignment(.trailing)
                                    Spacer()
                                }
                                .frame(width: 80, height: UIScreen.height / 14 - 25)
                            }
                        }
                        .padding(.top, 36)

                        HStack(spacing: 0) {
                            ForEach(Array(paginatedDates[index]), id: \.self) { date in
                                VStack(spacing: 0) {
                                    Text(date.partBeforeComma)
                                        .font(Constants.Fonts.title4)
                                        .foregroundStyle(Constants.Colors.black)
                                        .multilineTextAlignment(.center)
                                        .frame(height: 35)
                                        .padding(.bottom, 8)

                                    ForEach(times, id: \.self) { time in
                                        GeometryReader { geometry in
                                            let cellHeight = geometry.size.height
                                            CellView(
                                                isSelectedTop: selectedCells.contains(CellIdentifier(date: date, time: "\(time) Top")),
                                                isSelectedBottom: selectedCells.contains(CellIdentifier(date: date, time: "\(time) Bottom")),
                                                isHighlightedTop: draggedCells.contains(CellIdentifier(date: date, time: "\(time) Top")),
                                                isHighlightedBottom: draggedCells.contains(CellIdentifier(date: date, time: "\(time) Bottom"))
                                            )
                                            .contentShape(Rectangle())
                                            .gesture(DragGesture(minimumDistance: 0)
                                                .onChanged { value in
                                                    let isTopHalf = value.location.y < cellHeight / 2
                                                    let identifier = CellIdentifier(date: date, time: isTopHalf ? "\(time) Top" : "\(time) Bottom")

                                                    if toggleSelectionMode == nil {
                                                        toggleSelectionMode = selectedCells.contains(identifier) ? false : true
                                                    }

                                                    if toggleSelectionMode == true {
                                                        draggedCells.insert(identifier)
                                                    } else {
                                                        draggedCells.insert(identifier)
                                                    }
                                                }
                                                .onEnded { _ in
                                                    if let toggleSelectionMode = toggleSelectionMode {
                                                        if toggleSelectionMode {
                                                            selectedCells.formUnion(draggedCells)
                                                        } else {
                                                            selectedCells.subtract(draggedCells)
                                                        }
                                                    }
                                                    draggedCells.removeAll()
                                                    toggleSelectionMode = nil
                                                }
                                            )
                                            .onTapGesture {
                                                let isTopHalf = geometry.frame(in: .local).midY < cellHeight / 2
                                                toggleCellSelection(date: date, time: time, isTopHalf: isTopHalf)
                                            }
                                        }
                                        .frame(width: UIScreen.width / 5 + 10, height: UIScreen.height / 14 - 25)
                                    }
                                }
                            }
                        }
                    }
                    .offset(x: index < currentPage ? -UIScreen.main.bounds.width : index > currentPage ? UIScreen.main.bounds.width : 0)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }

            Spacer()

            PurpleButton(text: "Continue", action: saveAvailability)
        }
        .padding(.horizontal)
        .padding(.top)
        .background(Constants.Colors.white)
        .onAppear(perform: initializeSelectedCells)
    }

    // MARK: - Functions

    private func initializeSelectedCells() {
        for block in selectedDates {
            let startDate = block.startDate.dateValue()

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

    private func createDate(from dateString: String, timeString: String) -> AvailabilityBlock? {
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

            return AvailabilityBlock(startDate: Timestamp(date: parsedDate))
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

    var body: some View {
        ZStack {
            Rectangle()
                .fill(isHighlightedTop
                      ? (isSelectedTop ? Constants.Colors.resellPurple.opacity(0.3) : Constants.Colors.resellPurple.opacity(0.5))
                      : (isSelectedTop ? Constants.Colors.resellPurple : Color.clear))
                .frame(width: UIScreen.width / 5 + 10, height: (UIScreen.height / 14 - 25) / 2)
                .offset(y: -(UIScreen.height / 14 - 25) / 4)

            Rectangle()
                .fill(isHighlightedBottom
                      ? (isSelectedBottom ? Constants.Colors.resellPurple.opacity(0.3) : Constants.Colors.resellPurple.opacity(0.5))
                      : (isSelectedBottom ? Constants.Colors.resellPurple : Color.clear))
                .frame(width: UIScreen.width / 5 + 10, height: (UIScreen.height / 14 - 25) / 2)
                .offset(y: (UIScreen.height / 14 - 25) / 4)

            Rectangle()
                .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                .frame(width: UIScreen.width / 5 + 10, height: UIScreen.height / 14 - 25)
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

func generateTimes() -> [String] {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"

    let startHour = 9
    let endHour = 22
    return (startHour...endHour).map { hour in
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
}
