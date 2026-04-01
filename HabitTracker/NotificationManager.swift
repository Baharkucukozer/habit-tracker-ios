//
//  NotificationManager.swift
//  HabitTracker
//
//  Created by Bahar Küçüközer on 19.03.2026.
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
            print("Notification permission granted: \(granted)")
        }
    }
    
    func scheduleNotification(for habit: Habit) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder"
        content.body = "Don't forget: \(habit.name)"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: habit.reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: habit.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Schedule notification error: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelNotification(for habit: Habit) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [habit.id.uuidString])
    }
    
    func updateNotification(for habit: Habit) {
        cancelNotification(for: habit)
        
        if habit.reminderEnabled {
            scheduleNotification(for: habit)
        }
    }
}
