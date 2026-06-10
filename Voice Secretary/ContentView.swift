//
//  ContentView.swift
//  Voice Secretary
//
//  Created by tianyu li on 2026-06-08.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var selectedHistoryType: HistoryType = .reminders
    @State private var selectedHistorySort: HistorySort = .defaultOrder
    @State private var completingReminderIDs: Set<UUID> = []
    @State private var completingShoppingIDs: Set<UUID> = []
    @State private var showJournalSavedMessage = false

    private enum HistoryType: String, CaseIterable, Identifiable {
        case reminders = "Reminders"
        case shopping = "Shopping"

        var id: String {
            rawValue
        }
    }

    private enum HistorySort: String, CaseIterable, Identifiable {
        case defaultOrder = "Default"
        case byTime = "By Time"
        case byAdded = "By Added"

        var id: String {
            rawValue
        }
    }

    var body: some View {
        TabView {
            homeTab
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            journalTab
                .tabItem {
                    Label("Journal", systemImage: "book.closed")
                }

            historyTab
                .tabItem {
                    Label("History", systemImage: "clock")
                }
        }
        .sheet(isPresented: $viewModel.isReviewing) {
            reviewSheet
        }
    }

    private var homeTab: some View {
        NavigationStack {
            VStack(spacing: 0) {
                activeInbox
                Divider()
                inputComposer
            }
            .navigationTitle("Home")
        }
    }

    private var activeInbox: some View {
        List {
            Section("Active Inbox") {
                if activeReminderItems.isEmpty && activeShoppingItems.isEmpty {
                    Text("You're all caught up.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(activeReminderItems) { item in
                        reminderRow(
                            for: item,
                            isCompleting: completingReminderIDs.contains(item.id)
                        ) {
                            completeReminderFromHome(item)
                        }
                    }

                    ForEach(activeShoppingItems) { item in
                        shoppingRow(
                            for: item,
                            isCompleting: completingShoppingIDs.contains(item.id)
                        ) {
                            completeShoppingFromHome(item)
                        }
                    }
                }
            }
        }
    }

    private var inputComposer: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showJournalSavedMessage {
                Label("Saved to Journal", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.green)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            HStack(alignment: .bottom, spacing: 8) {
                Picker("Category", selection: $viewModel.selectedCategory) {
                    ForEach(AppCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.menu)

                TextField("Tell me something to remember...", text: $viewModel.noteText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...8)

                Button {
                    handleComposerSubmit()
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if viewModel.selectedCategory == .reminder {
                DatePicker(
                    "Reminder Time",
                    selection: $viewModel.reminderDueDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }
        }
        .padding()
        .background(.bar)
    }

    private func handleComposerSubmit() {
        if viewModel.selectedCategory == .journal {
            if viewModel.saveJournalEntryFromComposer() {
                showSavedToJournalMessage()
            }
        } else {
            viewModel.startReview()
        }
    }

    private func showSavedToJournalMessage() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showJournalSavedMessage = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showJournalSavedMessage = false
            }
        }
    }

    private var reviewSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                ScrollView {
                    reviewSummary
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 260)

                HStack {
                    Button("Edit", role: .cancel) {
                        viewModel.cancelReview()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                    Button("Save") {
                        viewModel.confirmSave()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .disabled(viewModel.reviewText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
            .navigationTitle("Review Before Saving")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(reviewSheetHeight), .medium])
        .presentationDragIndicator(.visible)
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

    private var reviewSheetHeight: CGFloat {
        let baseHeight: CGFloat = viewModel.reviewCategory == .reminder ? 300 : 250
        let extraTextHeight = CGFloat(viewModel.reviewText.count / 40) * 20
        return min(baseHeight + extraTextHeight, 520)
    }

    private var journalTab: some View {
        NavigationStack {
            List {
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
            .navigationTitle("Journal")
        }
    }

    private var historyTab: some View {
        NavigationStack {
            List {
                Section {
                    Picker("History Type", selection: $selectedHistoryType) {
                        ForEach(HistoryType.allCases) { historyType in
                            Text(historyType.rawValue).tag(historyType)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if selectedHistoryType == .reminders {
                    Section {
                        if viewModel.reminderItems.isEmpty {
                            Text("No reminders yet")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(historyReminderItems) { item in
                                reminderRow(for: item)
                            }
                        }
                    } header: {
                        historySectionHeader(title: "Reminder History")
                    }
                } else {
                    Section {
                        if viewModel.shoppingItems.isEmpty {
                            Text("No shopping items yet")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(historyShoppingItems) { item in
                                shoppingRow(for: item)
                            }
                        }
                    } header: {
                        historySectionHeader(title: "Shopping History")
                    }
                }
            }
            .navigationTitle("History")
        }
    }

    private func historySectionHeader(title: String) -> some View {
        HStack {
            Text(title)

            Spacer()

            Menu {
                ForEach(HistorySort.allCases) { sort in
                    Button {
                        selectedHistorySort = sort
                    } label: {
                        if selectedHistorySort == sort {
                            Label(sort.rawValue, systemImage: "checkmark")
                        } else {
                            Text(sort.rawValue)
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.body)
            }
        }
    }

    private var activeReminderItems: [ReminderItem] {
        viewModel.reminderItems.filter { $0.isCompleted == false }
    }

    private var activeShoppingItems: [ShoppingItem] {
        viewModel.shoppingItems.filter { $0.isCompleted == false }
    }

    private var historyReminderItems: [ReminderItem] {
        switch selectedHistorySort {
        case .defaultOrder:
            return viewModel.reminderItems.sorted { first, second in
                if first.isCompleted != second.isCompleted {
                    return first.isCompleted == false
                }

                return isReminderTimeEarlier(first, than: second)
            }
        case .byTime:
            return viewModel.reminderItems.sorted { first, second in
                isReminderTimeEarlier(first, than: second)
            }
        case .byAdded:
            return viewModel.reminderItems.sorted { first, second in
                first.createdAt > second.createdAt
            }
        }
    }

    private var historyShoppingItems: [ShoppingItem] {
        switch selectedHistorySort {
        case .defaultOrder:
            return viewModel.shoppingItems.sorted { first, second in
                if first.isCompleted != second.isCompleted {
                    return first.isCompleted == false
                }

                return first.createdAt > second.createdAt
            }
        case .byTime, .byAdded:
            return viewModel.shoppingItems.sorted { first, second in
                first.createdAt > second.createdAt
            }
        }
    }

    private func isReminderTimeEarlier(_ first: ReminderItem, than second: ReminderItem) -> Bool {
        switch (first.dueDate, second.dueDate) {
        case let (firstDate?, secondDate?):
            if firstDate != secondDate {
                return firstDate < secondDate
            }
            return first.createdAt > second.createdAt
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return first.createdAt > second.createdAt
        }
    }

    private func completeReminderFromHome(_ item: ReminderItem) {
        guard completingReminderIDs.contains(item.id) == false else {
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            _ = completingReminderIDs.insert(item.id)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            guard let currentItem = viewModel.reminderItems.first(where: { $0.id == item.id }),
                  currentItem.isCompleted == false else {
                completingReminderIDs.remove(item.id)
                return
            }

            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.toggleReminder(currentItem)
                completingReminderIDs.remove(item.id)
            }
        }
    }

    private func completeShoppingFromHome(_ item: ShoppingItem) {
        guard completingShoppingIDs.contains(item.id) == false else {
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            _ = completingShoppingIDs.insert(item.id)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            guard let currentItem = viewModel.shoppingItems.first(where: { $0.id == item.id }),
                  currentItem.isCompleted == false else {
                completingShoppingIDs.remove(item.id)
                return
            }

            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.toggleShoppingItem(currentItem)
                completingShoppingIDs.remove(item.id)
            }
        }
    }

    private func reminderRow(
        for item: ReminderItem,
        isCompleting: Bool = false,
        action: (() -> Void)? = nil
    ) -> some View {
        let isCompleted = item.isCompleted || isCompleting

        return Button {
            if let action = action {
                action()
            } else {
                viewModel.toggleReminder(item)
            }
        } label: {
            HStack(alignment: .top) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.text)
                        .strikethrough(isCompleted)

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
        .foregroundStyle(isCompleted ? .secondary : .primary)
        .opacity(isCompleting ? 0.6 : 1)
    }

    private func shoppingRow(
        for item: ShoppingItem,
        isCompleting: Bool = false,
        action: (() -> Void)? = nil
    ) -> some View {
        let isCompleted = item.isCompleted || isCompleting

        return Button {
            if let action = action {
                action()
            } else {
                viewModel.toggleShoppingItem(item)
            }
        } label: {
            HStack {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                Text(item.text)
                    .strikethrough(isCompleted)
                Spacer()
            }
        }
        .foregroundStyle(isCompleted ? .secondary : .primary)
        .opacity(isCompleting ? 0.6 : 1)
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
