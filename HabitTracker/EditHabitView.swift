//
//  EditHabitView.swift
//  HabitTracker
//

import SwiftUI

struct EditHabitView: View {

    @Environment(\.dismiss) var dismiss
    @Binding var habit: Habit
    var saveHabits: () -> Void

    @State private var habitName: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var frequency: HabitFrequency
    @State private var selectedDays: Set<Int>
    @State private var timesPerWeek: Int
    @State private var dailyTarget: Int

    init(habit: Binding<Habit>, saveHabits: @escaping () -> Void) {
        self._habit = habit
        self.saveHabits = saveHabits
        _habitName = State(initialValue: habit.wrappedValue.name)
        _selectedIcon = State(initialValue: habit.wrappedValue.iconName)
        _selectedColor = State(initialValue: habit.wrappedValue.colorName)
        _reminderEnabled = State(initialValue: habit.wrappedValue.reminderEnabled)
        _reminderTime = State(initialValue: habit.wrappedValue.reminderTime)
        _frequency = State(initialValue: habit.wrappedValue.frequency)
        _dailyTarget = State(initialValue: habit.wrappedValue.dailyTarget)

        switch habit.wrappedValue.frequency {
        case .specificDays(let days):
            _selectedDays = State(initialValue: Set(days))
            _timesPerWeek = State(initialValue: 3)
        case .timesPerWeek(let times):
            _selectedDays = State(initialValue: [])
            _timesPerWeek = State(initialValue: times)
        default:
            _selectedDays = State(initialValue: [])
            _timesPerWeek = State(initialValue: 3)
        }
    }

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
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveEdit() }
                        .fontWeight(.semibold)
                        .disabled(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
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
                Text(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Habit name" : habitName)
                    .font(.headline)
                Text(dailyTarget > 1 ? "\(frequency.label) · \(dailyTarget)x per day" : frequency.label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color(.secondarySystemBackground)))
    }

    // MARK: - Name

    var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Habit Name").font(.headline)
            TextField("e.g. Drink water", text: $habitName)
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
        }
    }

    // MARK: - Icon

    var iconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose an Icon").font(.headline)
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
            Text("Choose a Color").font(.headline)
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
            Text("Frequency").font(.headline)
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
            Text("Times per Day").font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(dailyTarget == 1 ? "Once a day" : "\(dailyTarget) times a day")
                        .font(.subheadline).foregroundColor(.primary)
                    Text(dailyTarget == 1 ? "Tap once to complete" : "Tap + each time you do it")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Stepper("", value: $dailyTarget, in: 1...10).fixedSize()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))

            if dailyTarget > 1 {
                HStack(spacing: 6) {
                    Text("Progress looks like:").font(.caption).foregroundColor(.secondary)
                    ForEach(0..<dailyTarget, id: \.self) { _ in
                        Circle().fill(Color(.systemFill)).frame(width: 10, height: 10)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Reminder

    var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminder").font(.headline)
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

    func saveEdit() {
        let trimmed = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        habit.name = trimmed
        habit.iconName = selectedIcon
        habit.colorName = selectedColor
        habit.reminderEnabled = reminderEnabled
        habit.reminderTime = reminderTime
        habit.frequency = frequency
        habit.dailyTarget = dailyTarget
        // Reset count if target changed to avoid stale state
        if dailyTarget != habit.dailyTarget {
            habit.completionCount = 0
            habit.isCompleted = false
        }

        NotificationManager.shared.updateNotification(for: habit)
        saveHabits()
        dismiss()
    }
}
