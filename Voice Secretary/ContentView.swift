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
            .sheet(isPresented: $viewModel.isReviewing) {
                reviewSheet
            }
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

            Button("Review") {
                viewModel.startReview()
            }
            .disabled(viewModel.noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var reviewSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                reviewSummary

                Spacer()

                Button("Confirm Save") {
                    viewModel.confirmSave()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(viewModel.reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Edit", role: .cancel) {
                    viewModel.cancelReview()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .navigationTitle("Review Before Saving")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    private var reviewSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(reviewTitle)
                .font(.headline)

            Text(viewModel.reviewText)
                .font(.body)

            if viewModel.reviewCategory == .journal {
                Text("Saved with current date/time")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if viewModel.reviewCategory == .reminder {
                Text("Reminder Time: \(viewModel.reviewReminderDueDate.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(viewModel.reviewReminderDueDate > Date() ? "A notification will be scheduled." : "No notification will be scheduled.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var reviewTitle: String {
        switch viewModel.reviewCategory {
        case .journal:
            return "Save as Journal Entry"
        case .reminder:
            return "Save as Reminder"
        case .shopping:
            return "Add to Shopping List"
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
