import SwiftUI
import JarvisCore

/// Unified inbox view showing all incoming items
public struct InboxView: View {
    @StateObject private var viewModel: InboxViewModel
    @State private var showFilterPicker = false
    @State private var showSortPicker = false
    @State private var showSnoozeSheet = false
    @State private var itemToSnooze: Item?
    @State private var snoozeDate = Date().addingTimeInterval(3600) // 1 hour default

    /// Initialize with dependencies
    public init(itemStorage: any ItemStorageProtocol, userId: UUID) {
        _viewModel = StateObject(wrappedValue: InboxViewModel(
            itemStorage: itemStorage,
            userId: userId
        ))
    }

    /// Initialize with default in-memory storage (sample data loaded on appear)
    public init() {
        let storage = InMemoryItemStorage()
        let userId = UUID()
        _viewModel = StateObject(wrappedValue: InboxViewModel(
            itemStorage: storage,
            userId: userId,
            loadSampleData: true
        ))
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Inbox")
                .toolbar {
                    toolbarContent
                }
                .refreshable {
                    await viewModel.refresh()
                }
                .sheet(isPresented: $showSnoozeSheet) {
                    snoozeSheet
                }
        }
        .task {
            await viewModel.loadItems()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            loadingView
        } else if viewModel.showZeroInboxState {
            zeroInboxView
        } else {
            itemsList
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading inbox...")
                .foregroundStyle(.secondary)
        }
    }

    private var zeroInboxView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("Zero Inbox!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("You've processed all your items. Great job!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private var itemsList: some View {
        List {
            // Error message if any
            if let error = viewModel.errorMessage {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.yellow)
                        Text(error)
                            .font(.caption)
                    }
                }
            }

            // Batch actions if items selected
            if !viewModel.selectedItems.isEmpty {
                batchActionsSection
            }

            // Grouped items by urgency
            ForEach(UrgencyGroup.allCases) { group in
                let groupItems = viewModel.groupedItems[group] ?? []
                if !groupItems.isEmpty {
                    Section {
                        ForEach(groupItems) { item in
                            InboxItemRow(
                                item: item,
                                isSelected: viewModel.selectedItems.contains(item.id),
                                onSelect: { viewModel.toggleSelection(item) },
                                onQuickAction: { action in
                                    handleQuickAction(action, for: item)
                                }
                            )
                        }
                    } header: {
                        urgencyHeader(for: group, count: groupItems.count)
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
    }

    private func urgencyHeader(for group: UrgencyGroup, count: Int) -> some View {
        HStack {
            Image(systemName: group.icon)
                .foregroundStyle(group.color)
            Text(group.rawValue)
            Spacer()
            Text("\(count)")
                .foregroundStyle(.secondary)
        }
    }

    private var batchActionsSection: some View {
        Section {
            HStack {
                Text("\(viewModel.selectedItems.count) selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Clear") {
                    viewModel.clearSelection()
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 16) {
                Button {
                    Task {
                        await viewModel.archiveSelected()
                    }
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }

                Button {
                    Task {
                        await viewModel.moveSelectedToToday()
                    }
                } label: {
                    Label("Today", systemImage: "sun.max")
                }

                Button(role: .destructive) {
                    Task {
                        await viewModel.deleteSelected()
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .buttonStyle(.bordered)
        } header: {
            Text("Batch Actions")
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                // Filter options
                Section("Filter") {
                    ForEach(InboxFilter.allCases) { filter in
                        Button {
                            viewModel.filterType = filter
                        } label: {
                            if viewModel.filterType == filter {
                                Label(filter.rawValue, systemImage: "checkmark")
                            } else {
                                Text(filter.rawValue)
                            }
                        }
                    }
                }

                // Sort options
                Section("Sort") {
                    ForEach(InboxSortOrder.allCases) { order in
                        Button {
                            viewModel.sortOrder = order
                        } label: {
                            if viewModel.sortOrder == order {
                                Label(order.rawValue, systemImage: "checkmark")
                            } else {
                                Text(order.rawValue)
                            }
                        }
                    }
                }

                Divider()

                // Selection mode
                Button {
                    if viewModel.selectedItems.isEmpty {
                        viewModel.selectAll()
                    } else {
                        viewModel.clearSelection()
                    }
                } label: {
                    if viewModel.selectedItems.isEmpty {
                        Label("Select All", systemImage: "checkmark.circle")
                    } else {
                        Label("Clear Selection", systemImage: "xmark.circle")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }

        ToolbarItem(placement: .status) {
            if viewModel.inboxCount > 0 {
                Text("\(viewModel.inboxCount) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Snooze Sheet

    private var snoozeSheet: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Snooze until",
                        selection: $snoozeDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section {
                    Button("Later Today") {
                        snoozeDate = Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date()
                    }
                    Button("Tomorrow Morning") {
                        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                        components.day! += 1
                        components.hour = 9
                        snoozeDate = Calendar.current.date(from: components) ?? Date()
                    }
                    Button("Next Week") {
                        snoozeDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
                    }
                }
            }
            .navigationTitle("Snooze")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showSnoozeSheet = false
                        itemToSnooze = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Snooze") {
                        if let item = itemToSnooze {
                            Task {
                                await viewModel.snooze(item, until: snoozeDate)
                            }
                        }
                        showSnoozeSheet = false
                        itemToSnooze = nil
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Quick Action Handling

    private func handleQuickAction(_ action: QuickAction, for item: Item) {
        Task {
            switch action {
            case .archive:
                await viewModel.archive(item)
            case .complete:
                await viewModel.complete(item)
            case .moveToToday:
                await viewModel.moveToToday(item)
            case .snooze:
                itemToSnooze = item
                showSnoozeSheet = true
            case .delete:
                await viewModel.delete(item)
            case .reply, .addTask, .delegate:
                // These would trigger navigation or sheets
                // For now just log
                print("Action \(action.rawValue) for item \(item.id)")
            }
        }
    }
}

#Preview {
    InboxView()
}
