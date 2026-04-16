//
//  HabitsView.swift
//  HabitTracker
//
//  Created by Bahar Küçüközer on 18.03.2026.
//

import SwiftUI

struct HabitsView: View {

    @Binding var habits: [Habit]
    @State private var showingAddHabit = false
    @State private var editingHabitID: UUID? = nil
    @State private var isEditMode = false

    var completedTodayCount: Int {
        habits.filter { $0.isFullyCompletedToday && $0.isScheduled(on: Date()) }.count
    }

    var scheduledTodayCount: Int {
        habits.filter { $0.isScheduled(on: Date()) }.count
    }

    var progressValue: Double {
        guard scheduledTodayCount > 0 else { return 0 }
        return Double(completedTodayCount) / Double(scheduledTodayCount)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.blue.opacity(0.06),
                        Color.purple.opacity(0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    summaryCard

                    if habits.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach($habits) { $habit in
                                habitRow(habit: $habit)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                        Button {
                                            editingHabitID = habit.id
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteHabit(habit)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                            .onMove(perform: moveHabits)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .environment(\.editMode, .constant(isEditMode ? .active : .inactive))
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("My Habits")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !habits.isEmpty {
                        Button {
                            withAnimation { isEditMode.toggle() }
                        } label: {
                            Text(isEditMode ? "Done" : "Edit")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus").font(.headline)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(habits: $habits, saveHabits: saveHabits)
            }
            .sheet(item: Binding(
                get: { editingHabitID.flatMap { id in habits.first(where: { $0.id == id }).map { _ in id } } },
                set: { editingHabitID = $0 }
            )) { id in
                if let index = habits.firstIndex(where: { $0.id == id }) {
                    EditHabitView(habit: $habits[index], saveHabits: saveHabits)
                }
            }
            .onAppear {
                refreshDailyCompletionState()
            }
        }
    }

    // MARK: - Summary card

    var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(.headline)
                    Text(scheduledTodayCount == 0
                         ? "No habits scheduled today"
                         : "\(completedTodayCount) of \(scheduledTodayCount) habits completed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.08), lineWidth: 8)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: progressValue)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 52, height: 52)
                    Text("\(Int(progressValue * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }

            ProgressView(value: progressValue)
                .tint(.blue)

            if scheduledTodayCount > 0 && completedTodayCount == scheduledTodayCount {
                Text("Great job — all habits done for today.")
                    .font(.footnote)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }

    // MARK: - Empty state

    var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "checkmark.circle.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(.blue, .purple)
            Text("No habits yet")
                .font(.title3)
                .fontWeight(.bold)
            Text("Tap the + button to create your first habit and start tracking your daily progress.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
        }
    }

    // MARK: - Habit row

    func habitRow(habit: Binding<Habit>) -> some View {
        let currentHabit = habit.wrappedValue
        let scheduledToday = currentHabit.isScheduled(on: Date())
        let isMulti = currentHabit.dailyTarget > 1

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(currentHabit.themeColor.opacity(scheduledToday ? 0.16 : 0.08))
                    .frame(width: 46, height: 46)
                Image(systemName: currentHabit.iconName)
                    .font(.title3)
                    .foregroundColor(scheduledToday ? currentHabit.themeColor : .secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(currentHabit.name)
                    .font(.headline)
                    .strikethrough(currentHabit.isFullyCompletedToday, color: currentHabit.themeColor)
                    .foregroundColor(currentHabit.isFullyCompletedToday ? .secondary : (scheduledToday ? .primary : .secondary))

                HStack(spacing: 10) {
                    if !scheduledToday {
                        Text("Not scheduled today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if isMulti {
                        Text("\(currentHabit.completionCount) of \(currentHabit.dailyTarget) done")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(currentHabit.isFullyCompletedToday ? "Completed today" : "Not completed yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Label("\(currentHabit.streakCount)", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }

                Text(currentHabit.frequency.label)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if currentHabit.reminderEnabled {
                    Text("Reminder: \(formattedTime(currentHabit.reminderTime))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Right side controls
            if isEditMode {
                // Edit pill
                Button {
                    editingHabitID = currentHabit.id
                } label: {
                    Text("Edit")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .overlay(Capsule().stroke(Color.blue, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .transition(.opacity)

            } else if scheduledToday {
                if isMulti {
                    // Multi-target counter UI
                    multiCounterView(habit: habit)
                        .transition(.opacity)
                } else {
                    // Standard single checkmark
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                            toggleSingleHabit(for: habit)
                            saveHabits()
                        }
                    } label: {
                        Image(systemName: currentHabit.isFullyCompletedToday ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(currentHabit.isFullyCompletedToday ? currentHabit.themeColor : .gray.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(currentHabit.themeColor.opacity(scheduledToday ? 0.12 : 0.05), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 3)
        .opacity(scheduledToday ? 1.0 : 0.5)
    }

    // MARK: - Multi counter view

    func multiCounterView(habit: Binding<Habit>) -> some View {
        let current = habit.wrappedValue
        let done = current.isFullyCompletedToday

        return VStack(spacing: 6) {
            // Dot indicators
            HStack(spacing: 4) {
                ForEach(0..<current.dailyTarget, id: \.self) { index in
                    Circle()
                        .fill(index < current.completionCount
                              ? current.themeColor
                              : Color(.systemFill))
                        .frame(width: 10, height: 10)
                }
            }

            // Plus button or checkmark
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                    if done {
                        // Tap checkmark to reset
                        resetMultiHabit(for: habit)
                    } else {
                        // Increment count
                        incrementHabit(for: habit)
                    }
                    saveHabits()
                }
            } label: {
                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(current.themeColor)
                } else {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 32, height: 32)
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(current.themeColor)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: "Habits")
        }
    }

    func deleteHabit(_ habit: Habit) {
        withAnimation {
            habits.removeAll { $0.id == habit.id }
            NotificationManager.shared.cancelNotification(for: habit)
            saveHabits()
        }
    }

    func moveHabits(from source: IndexSet, to destination: Int) {
        habits.move(fromOffsets: source, toOffset: destination)
        saveHabits()
    }

    // MARK: - Single habit toggle (dailyTarget == 1)

    func toggleSingleHabit(for habit: Binding<Habit>) {
        let calendar = Calendar.current
        let today = Date()

        if habit.wrappedValue.isFullyCompletedToday {
            habit.wrappedValue.isCompleted = false
            habit.wrappedValue.completionCount = 0
            habit.wrappedValue.completionHistory.removeAll { calendar.isDateInToday($0) }
            return
        }

        if let lastDate = habit.wrappedValue.lastCompletedDate {
            if calendar.isDateInToday(lastDate) {
                habit.wrappedValue.isCompleted = true
                habit.wrappedValue.completionCount = 1
                let alreadyRecorded = habit.wrappedValue.completionHistory.contains { calendar.isDateInToday($0) }
                if !alreadyRecorded { habit.wrappedValue.completionHistory.append(today) }
                return
            }
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
               calendar.isDate(lastDate, inSameDayAs: yesterday) {
                habit.wrappedValue.streakCount += 1
            } else {
                habit.wrappedValue.streakCount = 1
            }
        } else {
            habit.wrappedValue.streakCount = 1
        }

        habit.wrappedValue.isCompleted = true
        habit.wrappedValue.completionCount = 1
        habit.wrappedValue.lastCompletedDate = today
        let alreadyRecorded = habit.wrappedValue.completionHistory.contains { calendar.isDateInToday($0) }
        if !alreadyRecorded { habit.wrappedValue.completionHistory.append(today) }
    }

    // MARK: - Multi habit increment (dailyTarget > 1)

    func incrementHabit(for habit: Binding<Habit>) {
        let calendar = Calendar.current
        let today = Date()

        habit.wrappedValue.completionCount += 1

        // Check if we just hit the target
        if habit.wrappedValue.completionCount >= habit.wrappedValue.dailyTarget {
            habit.wrappedValue.isCompleted = true

            // Streak logic
            if let lastDate = habit.wrappedValue.lastCompletedDate {
                if !calendar.isDateInToday(lastDate) {
                    if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                       calendar.isDate(lastDate, inSameDayAs: yesterday) {
                        habit.wrappedValue.streakCount += 1
                    } else {
                        habit.wrappedValue.streakCount = 1
                    }
                }
            } else {
                habit.wrappedValue.streakCount = 1
            }

            habit.wrappedValue.lastCompletedDate = today
            let alreadyRecorded = habit.wrappedValue.completionHistory.contains { calendar.isDateInToday($0) }
            if !alreadyRecorded { habit.wrappedValue.completionHistory.append(today) }
        }
    }

    // MARK: - Reset multi habit

    func resetMultiHabit(for habit: Binding<Habit>) {
        let calendar = Calendar.current
        habit.wrappedValue.isCompleted = false
        habit.wrappedValue.completionCount = 0
        habit.wrappedValue.completionHistory.removeAll { calendar.isDateInToday($0) }
    }

    // MARK: - Daily refresh

    func refreshDailyCompletionState() {
        let calendar = Calendar.current
        let today = Date()
        for index in habits.indices {
            if let lastDate = habits[index].lastCompletedDate,
               !calendar.isDate(lastDate, inSameDayAs: today) {
                habits[index].isCompleted = false
                habits[index].completionCount = 0
            }
        }
        saveHabits()
    }
}

// MARK: - UUID Identifiable conformance for sheet(item:)
extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}
