//
//  HabitCalendarView.swift
//  HabitTracker
//

import SwiftUI

struct HabitCalendarView: View {

    let habits: [Habit]

    @State private var displayedMonth: Date = {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        return cal.date(from: comps) ?? Date()
    }()

    @State private var selectedDate: Date? = nil

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    private var weekdaySymbols: [String] {
        calendar.shortWeekdaySymbols.map { String($0.prefix(2)) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.green.opacity(0.05),
                        Color.teal.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        monthNavigator
                        weekdayHeader
                        dayGrid
                        if let date = selectedDate {
                            habitListForDay(date: date)
                        } else {
                            placeholderPrompt
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Calendar")
        }
    }

    // MARK: - Month navigator

    var monthNavigator: some View {
        HStack {
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            Spacer()

            Text(monthYearString(for: displayedMonth))
                .font(.headline)

            Spacer()

            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundColor(isCurrentMonth ? .gray.opacity(0.4) : .blue)
            }
            .disabled(isCurrentMonth)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Weekday header

    var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Day grid

    var dayGrid: some View {
        let days = daysInMonth()

        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                if let date = date {
                    let rate = completionRate(for: date)
                    let perfect = isPerfectDay(date)
                    let isSelected = selectedDate.map {
                        calendar.isDate($0, inSameDayAs: date)
                    } ?? false

                    DayCell(
                        date: date,
                        completionRate: rate,
                        isPerfect: perfect,
                        isToday: calendar.isDateInToday(date),
                        isFuture: date > Date(),
                        isSelected: isSelected
                    )
                    .onTapGesture {
                        if isSelected {
                            selectedDate = nil
                        } else {
                            selectedDate = date
                        }
                    }
                } else {
                    Color.clear.frame(height: 38)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Habit list for selected day

    func habitListForDay(date: Date) -> some View {
        let completedHabits = habits.filter { $0.wasCompleted(on: date) }
        let missedHabits = habits.filter { !$0.wasCompleted(on: date) }
        let dateLabel = formattedDate(date)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(dateLabel)
                    .font(.headline)
                if isPerfectDay(date) {
                    Image(systemName: "star.fill")
                        .foregroundColor(Color(hex: "#F59E0B"))
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 4)

            if habits.isEmpty {
                Text("No habits tracked yet.")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            } else {
                if !completedHabits.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(completedHabits) { habit in
                            habitSummaryRow(habit: habit, done: true)
                        }
                    }
                }

                if !missedHabits.isEmpty && !isFutureDate(date) {
                    VStack(spacing: 8) {
                        ForEach(missedHabits) { habit in
                            habitSummaryRow(habit: habit, done: false)
                        }
                    }
                }

                if isFutureDate(date) {
                    Text("Future date — no data yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                }
            }
        }
    }

    func habitSummaryRow(habit: Habit, done: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(habit.themeColor.opacity(done ? 0.18 : 0.08))
                    .frame(width: 38, height: 38)
                Image(systemName: habit.iconName)
                    .font(.subheadline)
                    .foregroundColor(done ? habit.themeColor : .secondary)
            }

            Text(habit.name)
                .font(.subheadline)
                .foregroundColor(done ? .primary : .secondary)

            Spacer()

            Image(systemName: done ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(done ? habit.themeColor : .secondary.opacity(0.5))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    var placeholderPrompt: some View {
        Text("Tap a day to see which habits were completed.")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }

    // MARK: - Helpers

    func isPerfectDay(_ date: Date) -> Bool {
        guard !habits.isEmpty else { return false }
        return habits.allSatisfy { $0.wasCompleted(on: date) }
    }

    func completionRate(for date: Date) -> Double {
        guard !habits.isEmpty else { return 0 }
        let completed = habits.filter { $0.wasCompleted(on: date) }.count
        return Double(completed) / Double(habits.count)
    }

    var isCurrentMonth: Bool {
        calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month)
    }

    func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newDate
        }
    }

    func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    func isFutureDate(_ date: Date) -> Bool {
        calendar.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
    }

    func daysInMonth() -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: displayedMonth)
        let leadingEmpties = firstWeekday - 1
        var days: [Date?] = Array(repeating: nil, count: leadingEmpties)
        for day in range {
            var comps = calendar.dateComponents([.year, .month], from: displayedMonth)
            comps.day = day
            days.append(calendar.date(from: comps))
        }
        return days
    }
}

// MARK: - Day cell

private struct DayCell: View {

    let date: Date
    let completionRate: Double
    let isPerfect: Bool
    let isToday: Bool
    let isFuture: Bool
    let isSelected: Bool

    private let goldColor = Color(hex: "#F59E0B")

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    var body: some View {
        ZStack {
            if isPerfect {
                // White background with gold ring
                Circle()
                    .fill(Color.white)
                Circle()
                    .strokeBorder(goldColor, lineWidth: 2)
            } else {
                Circle()
                    .fill(cellBackground)
            }

            // Blue ring for today (only when not a perfect day)
            if isToday && !isPerfect {
                Circle()
                    .strokeBorder(Color.blue.opacity(0.6), lineWidth: 1.5)
            }

            // Blue ring for selected
            if isSelected && !isPerfect {
                Circle()
                    .strokeBorder(Color.blue, lineWidth: 2)
            }

            if isPerfect {
                Image(systemName: "star.fill")
                    .font(.system(size: 18))
                    .foregroundColor(goldColor)
            } else {
                Text(dayNumber)
                    .font(.system(size: 13, weight: isToday ? .bold : .regular))
                    .foregroundColor(textColor)
            }
        }
        .frame(width: 38, height: 38)
    }

    var cellBackground: Color {
        if isFuture { return Color.clear }
        if completionRate == 0 { return Color(.systemFill).opacity(0.6) }
        return Color.green.opacity(0.25 + (completionRate * 0.65))
    }

    var textColor: Color {
        if isFuture { return .secondary.opacity(0.4) }
        return .primary
    }
}

// MARK: - Hex color helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
