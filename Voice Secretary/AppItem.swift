//
//  AppItem.swift
//  Voice Secretary
//
//  Created by tianyu li on 2026-06-08.
//

import Foundation

enum AppCategory: String, CaseIterable, Identifiable, Codable {
    case journal = "Journal"
    case reminder = "Reminder"
    case shopping = "Shopping"

    var id: String {
        rawValue
    }
}

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let text: String
    let createdAt: Date
}

struct ReminderItem: Identifiable, Codable {
    let id: UUID
    let text: String
    let createdAt: Date
    let dueDate: Date?
    var isCompleted: Bool
}

struct ShoppingItem: Identifiable, Codable {
    let id: UUID
    let text: String
    let createdAt: Date
    var isCompleted: Bool
}
