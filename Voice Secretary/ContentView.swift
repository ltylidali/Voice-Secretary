//
//  ContentView.swift
//  Voice Secretary
//
//  Created by tianyu li on 2026-06-08.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        NavigationStack {
            List {
                inputSection
                journalSection
                remindersSection
                shoppingSection
            }
            .navigationTitle("Voice Secretary")
        }
    }

    private var inputSection: some View {
        Section("New Note") {
            TextField("Type a short note", text: $viewModel.noteText)

            Picker("Category", selection: $viewModel.selectedCategory) {
                ForEach(AppCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }

            if viewModel.selectedCategory == .reminder {
                DatePicker(
                    "Reminder Time",
                    selection: $viewModel.reminderDueDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }

            Button("Save") {
                viewModel.saveNote()
            }
            .disabled(viewModel.noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var journalSection: some View {
        Section("Journal Entries") {
            if viewModel.journalEntries.isEmpty {
                Text("No journal entries yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.journalEntries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(entry.text)
                    }
                }
            }
        }
    }

    private var remindersSection: some View {
        Section("Reminder Items") {
            if viewModel.reminderItems.isEmpty {
                Text("No reminders yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.reminderItems) { item in
                    Button {
                        viewModel.toggleReminder(item)
                    } label: {
                        HStack(alignment: .top) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.text)
                                    .strikethrough(item.isCompleted)

                                if let dueDate = item.dueDate {
                                    Text("Reminder Time: \(dueDate.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if let statusText = reminderStatusText(for: item) {
                                    Text(statusText)
                                        .font(.caption)
                                        .foregroundStyle(statusText == "Overdue" ? .red : .blue)
                                }
                            }

                            Spacer()
                        }
                    }
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                }
            }
        }
    }

    private var shoppingSection: some View {
        Section("Shopping Items") {
            if viewModel.shoppingItems.isEmpty {
                Text("No shopping items yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.shoppingItems) { item in
                    Button {
                        viewModel.toggleShoppingItem(item)
                    } label: {
                        HStack {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            Text(item.text)
                                .strikethrough(item.isCompleted)
                            Spacer()
                        }
                    }
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                }
            }
        }
    }

    private func reminderStatusText(for item: ReminderItem) -> String? {
        guard let dueDate = item.dueDate, item.isCompleted == false else {
            return nil
        }

        if dueDate < Date() {
            return "Overdue"
        }

        if Calendar.current.isDateInToday(dueDate) {
            return "Today"
        }

        return nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
