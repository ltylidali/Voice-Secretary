//
//  AppViewModel.swift
//  Voice Secretary
//
//  Created by tianyu li on 2026-06-08.
//

import Combine
import Foundation

final class AppViewModel: ObservableObject {
    @Published var noteText = ""
    @Published var selectedCategory: AppCategory = .journal
    @Published var reminderDueDate = Date()
    @Published var isReviewing = false
    @Published var reviewText = ""
    @Published var reviewCategory: AppCategory = .journal
    @Published var reviewReminderDueDate = Date()
    @Published private(set) var journalEntries: [JournalEntry] = []
    @Published private(set) var reminderItems: [ReminderItem] = []
    @Published private(set) var shoppingItems: [ShoppingItem] = []

    private let storageKey = "savedAppData"

    init() {
        loadItems()
        NotificationManager.shared.requestPermission()
    }

    func startReview() {
        let trimmedText = noteText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedText.isEmpty == false else {
            return
        }

        reviewText = trimmedText
        reviewCategory = selectedCategory
        reviewReminderDueDate = reminderDueDate
        isReviewing = true
    }

    func saveJournalEntryFromComposer() -> Bool {
        let trimmedText = noteText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedText.isEmpty == false else {
            return false
        }

        saveNote(text: trimmedText, category: .journal, reminderTime: reminderDueDate)

        noteText = ""
        selectedCategory = .journal
        reminderDueDate = Date()

        return true
    }

    func confirmSave() {
        let trimmedText = reviewText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedText.isEmpty == false else {
            return
        }

        saveNote(text: trimmedText, category: reviewCategory, reminderTime: reviewReminderDueDate)

        noteText = ""
        selectedCategory = .journal
        reminderDueDate = Date()
        clearReview()
    }

    func cancelReview() {
        clearReview()
    }

    private func saveNote(text: String, category: AppCategory, reminderTime: Date) {
        let now = Date()

        switch category {
        case .journal:
            let entry = JournalEntry(id: UUID(), text: text, createdAt: now)
            journalEntries.insert(entry, at: 0)
        case .reminder:
            let item = ReminderItem(
                id: UUID(),
                text: text,
                createdAt: now,
                dueDate: reminderTime,
                isCompleted: false
            )
            reminderItems.insert(item, at: 0)
            NotificationManager.shared.scheduleReminderNotification(for: item)
        case .shopping:
            let item = ShoppingItem(id: UUID(), text: text, createdAt: now, isCompleted: false)
            shoppingItems.insert(item, at: 0)
        }

        saveItems()
    }

    private func clearReview() {
        isReviewing = false
        reviewText = ""
        reviewCategory = .journal
        reviewReminderDueDate = Date()
    }

    func toggleReminder(_ item: ReminderItem) {
        guard let index = reminderItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        reminderItems[index].isCompleted.toggle()

        if reminderItems[index].isCompleted {
            NotificationManager.shared.cancelReminderNotification(for: reminderItems[index])
        } else {
            NotificationManager.shared.scheduleReminderNotification(for: reminderItems[index])
        }

        saveItems()
    }

    func toggleShoppingItem(_ item: ShoppingItem) {
        guard let index = shoppingItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        shoppingItems[index].isCompleted.toggle()
        saveItems()
    }

    private func saveItems() {
        let appData = AppData(
            journalEntries: journalEntries,
            reminderItems: reminderItems,
            shoppingItems: shoppingItems
        )

        do {
            let encodedData = try JSONEncoder().encode(appData)
            UserDefaults.standard.set(encodedData, forKey: storageKey)
        } catch {
            print("Could not save app data: \(error)")
        }
    }

    private func loadItems() {
        guard let savedData = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }

        do {
            let decodedData = try JSONDecoder().decode(AppData.self, from: savedData)
            journalEntries = decodedData.journalEntries
            reminderItems = decodedData.reminderItems
            shoppingItems = decodedData.shoppingItems
        } catch {
            print("Could not load app data: \(error)")
        }
    }
}

private struct AppData: Codable {
    var journalEntries: [JournalEntry]
    var reminderItems: [ReminderItem]
    var shoppingItems: [ShoppingItem]
}
