//
//  Habit.swift
//  HabitTracker
//
//  Created by Bahar Küçüközer on 18.03.2026.
//

import SwiftUI

// MARK: - Frequency

enum HabitFrequency: Codable, Equatable {
    case daily
    case specificDays([Int])   // 1 = Sunday, 2 = Monday ... 7 = Saturday
    case timesPerWeek(Int)

    enum CodingKeys: String, CodingKey {
        case type, days, times
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "specificDays":
            let days = try container.decode([Int].self, forKey: .days)
            self = .specificDays(days)
        case "timesPerWeek":
            let times = try container.decode(Int.self, forKey: .times)
            self = .timesPerWeek(times)
        default:
            self = .daily
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .daily:
            try container.encode("daily", forKey: .type)
        case .specificDays(let days):
            try container.encode("specificDays", forKey: .type)
            try container.encode(days, forKey: .days)
        case .timesPerWeek(let times):
            try container.encode("timesPerWeek", forKey: .type)
            try container.encode(times, forKey: .times)
        }
    }

    var label: String {
        switch self {
        case .daily:
            return "Every day"
        case .specificDays(let days):
            let sorted = days.sorted()
            let names = sorted.compactMap { weekdayShortName($0) }
            return names.joined(separator: ", ")
        case .timesPerWeek(let times):
            return "\(times)x per week"
        }
    }

    func isScheduled(on date: Date) -> Bool {
        let calendar = Calendar.current
        switch self {
        case .daily:
            return true
        case .specificDays(let days):
            let weekday = calendar.component(.weekday, from: date)
            return days.contains(weekday)
        case .timesPerWeek:
            return true
        }
    }

    private func weekdayShortName(_ weekday: Int) -> String? {
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        guard weekday >= 1 && weekday <= 7 else { return nil }
        return names[weekday - 1]
    }
}

// MARK: - Habit

struct Habit: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var isCompleted: Bool
    var streakCount: Int
    var lastCompletedDate: Date?
    var completionHistory: [Date]
    var iconName: String
    var colorName: String
    var reminderEnabled: Bool
    var reminderTime: Date
    var frequency: HabitFrequency
    var dailyTarget: Int      // how many times per day this habit must be done
    var completionCount: Int  // how many times done today so far

    init(
        id: UUID = UUID(),
        name: String,
        isCompleted: Bool = false,
        streakCount: Int = 0,
        lastCompletedDate: Date? = nil,
        completionHistory: [Date] = [],
        iconName: String = "checkmark.circle.fill",
        colorName: String = "blue",
        reminderEnabled: Bool = false,
        reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date(),
        frequency: HabitFrequency = .daily,
        dailyTarget: Int = 1,
        completionCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
        self.streakCount = streakCount
        self.lastCompletedDate = lastCompletedDate
        self.completionHistory = completionHistory
        self.iconName = iconName
        self.colorName = colorName
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.frequency = frequency
        self.dailyTarget = dailyTarget
        self.completionCount = completionCount
    }

    enum CodingKeys: String, CodingKey {
        case id, name, isCompleted, streakCount, lastCompletedDate
        case completionHistory, iconName, colorName, reminderEnabled, reminderTime
        case frequency, dailyTarget, completionCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        streakCount = try container.decodeIfPresent(Int.self, forKey: .streakCount) ?? 0
        lastCompletedDate = try container.decodeIfPresent(Date.self, forKey: .lastCompletedDate)
        completionHistory = try container.decodeIfPresent([Date].self, forKey: .completionHistory) ?? []
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName) ?? "checkmark.circle.fill"
        colorName = try container.decodeIfPresent(String.self, forKey: .colorName) ?? "blue"
        reminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? false
        reminderTime = try container.decodeIfPresent(Date.self, forKey: .reminderTime)
            ?? Calendar.current.date(from: DateComponents(hour: 20, minute: 0))
            ?? Date()
        frequency = try container.decodeIfPresent(HabitFrequency.self, forKey: .frequency) ?? .daily
        dailyTarget = try container.decodeIfPresent(Int.self, forKey: .dailyTarget) ?? 1
        completionCount = try container.decodeIfPresent(Int.self, forKey: .completionCount) ?? 0
    }

    var themeColor: Color {
        HabitTheme.color(for: colorName)
    }

    func wasCompleted(on date: Date) -> Bool {
        let calendar = Calendar.current
        return completionHistory.contains { calendar.isDate($0, inSameDayAs: date) }
    }

    func isScheduled(on date: Date) -> Bool {
        frequency.isScheduled(on: date)
    }

    /// True when today's completionCount has reached the dailyTarget
    var isFullyCompletedToday: Bool {
        completionCount >= dailyTarget
    }
}

// MARK: - HabitTheme

enum HabitTheme {
    static let iconOptions: [String] = [
        "figure.walk", "book.fill", "drop.fill", "heart.fill",
        "bed.double.fill", "leaf.fill", "brain.head.profile", "dumbbell.fill",
        "fork.knife", "sun.max.fill", "moon.fill", "checkmark.circle.fill"
    ]

    static let colorOptions: [String] = [
        "blue", "green", "orange", "purple", "pink", "red", "teal", "indigo"
    ]

    static func color(for name: String) -> Color {
        switch name {
        case "green":  return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink":   return .pink
        case "red":    return .red
        case "teal":   return .teal
        case "indigo": return .indigo
        default:       return .blue
        }
    }
}
