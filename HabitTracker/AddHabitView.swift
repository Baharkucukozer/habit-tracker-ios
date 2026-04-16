//
//  AddHabitView.swift
//  HabitTracker
//
//  Created by Bahar Küçüközer on 18.03.2026.
//

import SwiftUI

struct AddHabitView: View {

    @Environment(\.dismiss) var dismiss
    @Binding var habits: [Habit]
    var saveHabits: () -> Void

    @State private var habitName = ""
    @State private var selectedIcon = "checkmark.circle.fill"
    @State private var selectedColor = "blue"
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    @State private var frequency: HabitFrequency = .daily
    @State private var selectedDays: Set<Int> = []
    @State private var timesPerWeek: Int = 3
    @State private var dailyTarget: Int = 1

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        previewCard
                        nameSection
                        iconSection
                        colorSection
                        frequencySection
                        dailyTargetSection
                        reminderSection
                    }
                    .padding()
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveHabit() }
                        .fontWeight(.semibold)
                        .disabled(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                NotificationManager.shared.requestPermission()
            }
        }
    }

    // MARK: - Preview card

    var previewCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(HabitTheme.color(for: selectedColor).opacity(0.18))
                    .frame(width: 58, height: 58)
                Image(systemName: selectedIcon)
                    .font(.title2)
                    .foregroundColor(HabitTheme.color(for: selectedColor))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Your habit name" : habitName)
                    .font(.headline)
                Text(dailyTarget > 1 ? "\(frequency.label) · \(dailyTarget)x per day" : frequency.label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "circle")
                .font(.title2)
                .foregroundColor(.gray.opacity(0.7))
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(.secondarySystemBackground)))
    }

    // MARK: - Name

    var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Habit Name")
                .font(.headline)
            TextField("e.g. Drink water", text: $habitName)
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
        }
    }

    // MARK: - Icon

    var iconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose an Icon")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(HabitTheme.iconOptions, id: \.self) { icon in
                        Button { selectedIcon = icon } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(selectedIcon == icon
                                          ? HabitTheme.color(for: selectedColor).opacity(0.18)
                                          : Color(.secondarySystemBackground))
                                    .frame(width: 58, height: 58)
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundColor(selectedIcon == icon
                                                     ? HabitTheme.color(for: selectedColor) : .primary)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(selectedIcon == icon
                                            ? HabitTheme.color(for: selectedColor) : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Color

    var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a Color")
                .font(.headline)
            HStack(spacing: 14) {
                ForEach(HabitTheme.colorOptions, id: \.self) { colorName in
                    Button { selectedColor = colorName } label: {
                        ZStack {
                            Circle().fill(HabitTheme.color(for: colorName)).frame(width: 34, height: 34)
                            if selectedColor == colorName {
                                Circle().stroke(Color.primary.opacity(0.25), lineWidth: 3).frame(width: 44, height: 44)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
    }

    // MARK: - Frequency

    var frequencySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Frequency")
                .font(.headline)
            VStack(spacing: 0) {
                frequencyOption(title: "Every day", subtitle: "No days off", value: .daily)
                Divider().padding(.leading, 16)
                frequencyOption(title: "Specific days", subtitle: "Pick which days of the week", value: .specificDays([]))
                Divider().padding(.leading, 16)
                frequencyOption(title: "Times per week", subtitle: "Any \(timesPerWeek) days each week", value: .timesPerWeek(timesPerWeek))
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))

            if case .specificDays = frequency { dayPicker }
            if case .timesPerWeek = frequency { timesPerWeekStepper }
        }
    }

    func frequencyOption(title: String, subtitle: String, value: HabitFrequency) -> some View {
        let isSelected: Bool = {
            switch (frequency, value) {
            case (.daily, .daily): return true
            case (.specificDays, .specificDays): return true
            case (.timesPerWeek, .timesPerWeek): return true
            default: return false
            }
        }()
        return Button {
            switch value {
            case .daily: frequency = .daily
            case .specificDays: frequency = .specificDays(Array(selectedDays).sorted())
            case .timesPerWeek: frequency = .timesPerWeek(timesPerWeek)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.subheadline).foregroundColor(.primary)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if isSelected { Image(systemName: "checkmark").foregroundColor(.blue).fontWeight(.semibold) }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    var dayPicker: some View {
        let days: [(Int, String)] = [(1,"S"),(2,"M"),(3,"T"),(4,"W"),(5,"T"),(6,"F"),(7,"S")]
        return HStack(spacing: 8) {
            ForEach(days, id: \.0) { weekday, letter in
                let selected = selectedDays.contains(weekday)
                Button {
                    if selected { selectedDays.remove(weekday) } else { selectedDays.insert(weekday) }
                    frequency = .specificDays(Array(selectedDays).sorted())
                } label: {
                    Text(letter).font(.subheadline).fontWeight(.semibold)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(selected ? Color.blue : Color(.systemFill)))
                        .foregroundColor(selected ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }

    var timesPerWeekStepper: some View {
        HStack {
            Text("Times per week").font(.subheadline)
            Spacer()
            Stepper("\(timesPerWeek)x", value: $timesPerWeek, in: 1...7)
                .onChange(of: timesPerWeek) { _, new in frequency = .timesPerWeek(new) }
                .fixedSize()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }

    // MARK: - Daily target

    var dailyTargetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Times per Day")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(dailyTarget == 1 ? "Once a day" : "\(dailyTarget) times a day")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text(dailyTarget == 1
                         ? "Tap once to complete"
                         : "Tap + each time you do it")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Stepper("", value: $dailyTarget, in: 1...10)
                    .fixedSize()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))

            // Dot preview
            if dailyTarget > 1 {
                HStack(spacing: 6) {
                    Text("Progress looks like:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(0..<dailyTarget, id: \.self) { _ in
                        Circle()
                            .fill(Color(.systemFill))
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Reminder

    var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminder")
                .font(.headline)
            Toggle("Enable daily reminder", isOn: $reminderEnabled)
            if reminderEnabled {
                DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
    }

    // MARK: - Save

    func saveHabit() {
        let trimmedName = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let newHabit = Habit(
            name: trimmedName,
            iconName: selectedIcon,
            colorName: selectedColor,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime,
            frequency: frequency,
            dailyTarget: dailyTarget
        )

        habits.append(newHabit)
        saveHabits()

        if newHabit.reminderEnabled {
            NotificationManager.shared.scheduleNotification(for: newHabit)
        }

        dismiss()
    }
}
