//
//  Habit.swift
//  HabitTracker
//
//  Created by Bahar Küçüközer on 18.03.2026.
//

import SwiftUI

struct Habit: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var isCompleted: Bool
    var streakCount: Int
    var lastCompletedDate: Date?
    var iconName: String
    var colorName: String
    var reminderEnabled: Bool
    var reminderTime: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        isCompleted: Bool = false,
        streakCount: Int = 0,
        lastCompletedDate: Date? = nil,
        iconName: String = "checkmark.circle.fill",
        colorName: String = "blue",
        reminderEnabled: Bool = false,
        reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    ) {
        self.id = id
        self.name = name
        self.isCompleted = isCompleted
        self.streakCount = streakCount
        self.lastCompletedDate = lastCompletedDate
        self.iconName = iconName
        self.colorName = colorName
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isCompleted
        case streakCount
        case lastCompletedDate
        case iconName
        case colorName
        case reminderEnabled
        case reminderTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        streakCount = try container.decodeIfPresent(Int.self, forKey: .streakCount) ?? 0
        lastCompletedDate = try container.decodeIfPresent(Date.self, forKey: .lastCompletedDate)
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName) ?? "checkmark.circle.fill"
        colorName = try container.decodeIfPresent(String.self, forKey: .colorName) ?? "blue"
        reminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? false
        reminderTime = try container.decodeIfPresent(Date.self, forKey: .reminderTime)
            ?? Calendar.current.date(from: DateComponents(hour: 20, minute: 0))
            ?? Date()
    }
    
    var themeColor: Color {
        HabitTheme.color(for: colorName)
    }
}

enum HabitTheme {
    static let iconOptions: [String] = [
        "figure.walk",
        "book.fill",
        "drop.fill",
        "heart.fill",
        "bed.double.fill",
        "leaf.fill",
        "brain.head.profile",
        "dumbbell.fill",
        "fork.knife",
        "sun.max.fill",
        "moon.fill",
        "checkmark.circle.fill"
    ]
    
    static let colorOptions: [String] = [
        "blue", "green", "orange", "purple", "pink", "red", "teal", "indigo"
    ]
    
    static func color(for name: String) -> Color {
        switch name {
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "teal": return .teal
        case "indigo": return .indigo
        default: return .blue
        }
    }
}
