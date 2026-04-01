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
    
    var completedTodayCount: Int {
        habits.filter { $0.isCompleted }.count
    }
    
    var progressValue: Double {
        guard !habits.isEmpty else { return 0 }
        return Double(completedTodayCount) / Double(habits.count)
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
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("My Habits")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !habits.isEmpty {
                        EditButton()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(habits: $habits, saveHabits: saveHabits)
            }
            .onAppear {
                refreshDailyCompletionState()
            }
        }
    }
    
    var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(.headline)
                    
                    Text("\(completedTodayCount) of \(habits.count) habits completed")
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
            
            if !habits.isEmpty && completedTodayCount == habits.count {
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
    
    func habitRow(habit: Binding<Habit>) -> some View {
        let currentHabit = habit.wrappedValue
        
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(currentHabit.themeColor.opacity(0.16))
                    .frame(width: 46, height: 46)
                
                Image(systemName: currentHabit.iconName)
                    .font(.title3)
                    .foregroundColor(currentHabit.themeColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(currentHabit.name)
                    .font(.headline)
                    .strikethrough(currentHabit.isCompleted, color: currentHabit.themeColor)
                    .foregroundColor(currentHabit.isCompleted ? .secondary : .primary)
                
                HStack(spacing: 10) {
                    Text(currentHabit.isCompleted ? "Completed today" : "Not completed yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(currentHabit.streakCount)", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                if currentHabit.reminderEnabled {
                    Text("Reminder: \(formattedTime(currentHabit.reminderTime))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                    toggleHabitCompletion(for: habit)
                    saveHabits()
                }
            } label: {
                Image(systemName: currentHabit.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(currentHabit.isCompleted ? currentHabit.themeColor : .gray.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(currentHabit.themeColor.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 3)
    }
    
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
    
    func toggleHabitCompletion(for habit: Binding<Habit>) {
        let calendar = Calendar.current
        let today = Date()
        
        if habit.wrappedValue.isCompleted {
            habit.wrappedValue.isCompleted = false
            return
        }
        
        if let lastDate = habit.wrappedValue.lastCompletedDate {
            if calendar.isDateInToday(lastDate) {
                habit.wrappedValue.isCompleted = true
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
        habit.wrappedValue.lastCompletedDate = today
    }
    
    func refreshDailyCompletionState() {
        let calendar = Calendar.current
        let today = Date()
        
        for index in habits.indices {
            if let lastDate = habits[index].lastCompletedDate,
               !calendar.isDate(lastDate, inSameDayAs: today) {
                habits[index].isCompleted = false
            }
        }
        
        saveHabits()
    }
}
