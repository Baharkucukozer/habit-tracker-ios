//
//  ContentView.swift
//  HabitTracker
//
//  Created by Bahar Küçüközer on 18.03.2026.
//

import SwiftUI

struct ContentView: View {
    
    @State private var habits: [Habit] = []
    
    var body: some View {
        TabView {
            HabitsView(habits: $habits)
                .tabItem {
                    Label("Habits", systemImage: "checklist")
                }
            
            HabitCalendarView(habits: habits)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            StatsView(habits: habits)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.xaxis")
                }
        }
        .onAppear {
            loadHabits()
        }
    }
    
    func loadHabits() {
        if let data = UserDefaults.standard.data(forKey: "Habits"),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded
        }
    }
}
