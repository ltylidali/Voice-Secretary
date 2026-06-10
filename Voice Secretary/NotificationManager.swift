//
//  NotificationManager.swift
//  Voice Secretary
//
//  Created by tianyu li on 2026-06-08.
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    private init() { }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                print("Notification permission error: \(error)")
            }

            if granted == false {
                print("Notification permission was not granted.")
            }
        }
    }

    func scheduleReminderNotification(for reminder: ReminderItem) {
        guard let reminderTime = reminder.dueDate else {
            return
        }

        guard reminderTime > Date() else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Voice Secretary Reminder"
        content.body = reminder.text
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: reminderTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: reminder.id),
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Could not schedule notification: \(error)")
            }
        }
    }

    func cancelReminderNotification(for reminder: ReminderItem) {
        cancelReminderNotification(id: reminder.id)
    }

    private func cancelReminderNotification(id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationIdentifier(for: id)]
        )
    }

    private func notificationIdentifier(for id: UUID) -> String {
        "reminder-\(id.uuidString)"
    }
}
