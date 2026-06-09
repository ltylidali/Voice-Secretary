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
    @Published private(set) var journalEntries: [JournalEntry] = []
    @Published private(set) var reminderItems: [ReminderItem] = []
    @Published private(set) var shoppingItems: [ShoppingItem] = []

    private let storageKey = "savedAppData"

    init() {
        loadItems()
    }

    func saveNote() {
        let trimmedText = noteText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedText.isEmpty == false else {
            return
        }

        let now = Date()

        switch selectedCategory {
        case .journal:
            let entry = JournalEntry(id: UUID(), text: trimmedText, createdAt: now)
            journalEntries.insert(entry, at: 0)
        case .reminder:
            let item = ReminderItem(
                id: UUID(),
                text: trimmedText,
                createdAt: now,
                dueDate: reminderDueDate,
                isCompleted: false
            )
            reminderItems.insert(item, at: 0)
        case .shopping:
            let item = ShoppingItem(id: UUID(), text: trimmedText, createdAt: now, isCompleted: false)
            shoppingItems.insert(item, at: 0)
        }

        noteText = ""
        reminderDueDate = Date()
        saveItems()
    }

    func toggleReminder(_ item: ReminderItem) {
        guard let index = reminderItems.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        reminderItems[index].isCompleted.toggle()
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
