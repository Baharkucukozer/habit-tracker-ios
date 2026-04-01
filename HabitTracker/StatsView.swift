//
//  StatsView.swift
//  HabitTracker
//
//  Created by Bahar Küçüközer on 18.03.2026.
//

import SwiftUI

struct StatsView: View {
    
    let habits: [Habit]
    
    var completedTodayCount: Int {
        habits.filter { $0.isCompleted }.count
    }
    
    var completionRate: Int {
        guard !habits.isEmpty else { return 0 }
        return Int((Double(completedTodayCount) / Double(habits.count)) * 100)
    }
    
    var bestHabit: Habit? {
        habits.max(by: { $0.streakCount < $1.streakCount })
    }
    
    var sortedHabitsByStreak: [Habit] {
        habits.sorted { $0.streakCount > $1.streakCount }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.orange.opacity(0.05),
                        Color.pink.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        topStatsGrid
                        bestStreakCard
                        streakListCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Stats")
        }
    }
    
    var topStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statCard(
                title: "Total Habits",
                value: "\(habits.count)",
                icon: "square.grid.2x2.fill",
                color: .blue
            )
            
            statCard(
                title: "Completed Today",
                value: "\(completedTodayCount)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            statCard(
                title: "Completion Rate",
                value: "\(completionRate)%",
                icon: "chart.bar.fill",
                color: .purple
            )
            
            statCard(
                title: "Best Streak",
                value: "\(bestHabit?.streakCount ?? 0)",
                icon: "flame.fill",
                color: .orange
            )
        }
    }
    
    func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    var bestStreakCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Habit")
                .font(.headline)
            
            if let bestHabit {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(bestHabit.themeColor.opacity(0.16))
                            .frame(width: 54, height: 54)
                        
                        Image(systemName: bestHabit.iconName)
                            .font(.title2)
                            .foregroundColor(bestHabit.themeColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bestHabit.name)
                            .font(.headline)
                        
                        Label("\(bestHabit.streakCount) day streak", systemImage: "flame.fill")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                }
            } else {
                Text("No habit data yet.")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    var streakListCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Habit Rankings")
                .font(.headline)
            
            if sortedHabitsByStreak.isEmpty {
                Text("Add some habits to see your streak rankings.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(sortedHabitsByStreak.enumerated()), id: \.element.id) { index, habit in
                    HStack(spacing: 12) {
                        Text("#\(index + 1)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .frame(width: 28)
                        
                        ZStack {
                            Circle()
                                .fill(habit.themeColor.opacity(0.16))
                                .frame(width: 38, height: 38)
                            
                            Image(systemName: habit.iconName)
                                .font(.subheadline)
                                .foregroundColor(habit.themeColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(habit.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(habit.isCompleted ? "Completed today" : "Not completed yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Label("\(habit.streakCount)", systemImage: "flame.fill")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    
                    if habit.id != sortedHabitsByStreak.last?.id {
                        Divider()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
