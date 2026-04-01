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
                        reminderSection
                    }
                    .padding()
                }
            }
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveHabit()
                    }
                    .fontWeight(.semibold)
                    .disabled(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                NotificationManager.shared.requestPermission()
            }
        }
    }
    
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
                
                Text("Preview of your new habit")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "circle")
                .font(.title2)
                .foregroundColor(.gray.opacity(0.7))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    var nameSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Habit Name")
                .font(.headline)
            
            TextField("e.g. Drink water", text: $habitName)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
        }
    }
    
    var iconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose an Icon")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(HabitTheme.iconOptions, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(selectedIcon == icon ? HabitTheme.color(for: selectedColor).opacity(0.18) : Color(.secondarySystemBackground))
                                    .frame(width: 58, height: 58)
                                
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundColor(selectedIcon == icon ? HabitTheme.color(for: selectedColor) : .primary)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(selectedIcon == icon ? HabitTheme.color(for: selectedColor) : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a Color")
                .font(.headline)
            
            HStack(spacing: 14) {
                ForEach(HabitTheme.colorOptions, id: \.self) { colorName in
                    Button {
                        selectedColor = colorName
                    } label: {
                        ZStack {
                            Circle()
                                .fill(HabitTheme.color(for: colorName))
                                .frame(width: 34, height: 34)
                            
                            if selectedColor == colorName {
                                Circle()
                                    .stroke(Color.primary.opacity(0.25), lineWidth: 3)
                                    .frame(width: 44, height: 44)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .padding(.top, 2)
        }
    }
    
    var reminderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminder")
                .font(.headline)
            
            Toggle("Enable daily reminder", isOn: $reminderEnabled)
            
            if reminderEnabled {
                DatePicker(
                    "Reminder Time",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    func saveHabit() {
        let trimmedName = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newHabit = Habit(
            name: trimmedName,
            isCompleted: false,
            streakCount: 0,
            lastCompletedDate: nil,
            iconName: selectedIcon,
            colorName: selectedColor,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime
        )
        
        habits.append(newHabit)
        saveHabits()
        
        if newHabit.reminderEnabled {
            NotificationManager.shared.scheduleNotification(for: newHabit)
        }
        
        dismiss()
    }
}
