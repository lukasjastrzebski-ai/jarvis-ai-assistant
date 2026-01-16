import SwiftUI
import JarvisCore

/// View model for the Unified Inbox
@MainActor
public class InboxViewModel: ObservableObject {
    // MARK: - Published State

    @Published public var items: [Item] = []
    @Published public var selectedItems: Set<UUID> = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var showZeroInboxState: Bool = false
    @Published public var filterType: InboxFilter = .all
    @Published public var sortOrder: InboxSortOrder = .newestFirst

    // MARK: - Dependencies

    private let itemStorage: any ItemStorageProtocol
    private let userId: UUID

    // MARK: - Computed Properties

    /// Items grouped by urgency
    public var groupedItems: [UrgencyGroup: [Item]] {
        var groups: [UrgencyGroup: [Item]] = [
            .urgent: [],
            .today: [],
            .thisWeek: [],
            .later: []
        ]

        let filtered = filteredItems
        for item in filtered {
            let group = urgencyGroup(for: item)
            groups[group, default: []].append(item)
        }

        return groups
    }

    /// Filtered items based on current filter
    public var filteredItems: [Item] {
        var result = items.filter { $0.status == .inbox }

        switch filterType {
        case .all:
            break
        case .email:
            result = result.filter { $0.sourceType == .email }
        case .calendar:
            result = result.filter { $0.sourceType == .calendar }
        case .tasks:
            result = result.filter { $0.itemType == .task }
        case .highPriority:
            result = result.filter { $0.priority >= .high }
        }

        // Sort
        switch sortOrder {
        case .newestFirst:
            result.sort { $0.createdAt > $1.createdAt }
        case .oldestFirst:
            result.sort { $0.createdAt < $1.createdAt }
        case .priorityFirst:
            result.sort { $0.priority > $1.priority }
        case .dueDate:
            result.sort {
                guard let date1 = $0.dueDate else { return false }
                guard let date2 = $1.dueDate else { return true }
                return date1 < date2
            }
        }

        return result
    }

    /// Count of items in inbox
    public var inboxCount: Int {
        items.filter { $0.status == .inbox }.count
    }

    /// Whether inbox is empty
    public var isInboxEmpty: Bool {
        inboxCount == 0
    }

    // MARK: - Initialization

    public init(itemStorage: any ItemStorageProtocol, userId: UUID) {
        self.itemStorage = itemStorage
        self.userId = userId
    }

    // MARK: - Actions

    /// Load items from storage
    public func loadItems() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await itemStorage.fetch(byUserId: userId)
            items = fetched
            showZeroInboxState = isInboxEmpty
        } catch {
            errorMessage = "Failed to load items: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Refresh items (pull-to-refresh)
    public func refresh() async {
        await loadItems()
    }

    /// Archive an item
    public func archive(_ item: Item) async {
        await updateStatus(item, to: .archived)
    }

    /// Complete an item
    public func complete(_ item: Item) async {
        var updated = item
        updated.status = .completed
        updated.completedAt = Date()
        updated.updatedAt = Date()
        await save(updated)
    }

    /// Move item to Today
    public func moveToToday(_ item: Item) async {
        await updateStatus(item, to: .today)
    }

    /// Snooze item to a later date
    public func snooze(_ item: Item, until date: Date) async {
        var updated = item
        updated.status = .scheduled
        updated.dueDate = date
        updated.updatedAt = Date()
        await save(updated)
    }

    /// Delete an item
    public func delete(_ item: Item) async {
        do {
            try await itemStorage.delete(byId: item.id)
            items.removeAll { $0.id == item.id }
            showZeroInboxState = isInboxEmpty
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
        }
    }

    /// Toggle item selection
    public func toggleSelection(_ item: Item) {
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
        } else {
            selectedItems.insert(item.id)
        }
    }

    /// Select all visible items
    public func selectAll() {
        selectedItems = Set(filteredItems.map { $0.id })
    }

    /// Clear selection
    public func clearSelection() {
        selectedItems.removeAll()
    }

    /// Batch archive selected items
    public func archiveSelected() async {
        for id in selectedItems {
            if let item = items.first(where: { $0.id == id }) {
                await archive(item)
            }
        }
        clearSelection()
    }

    /// Batch move selected to Today
    public func moveSelectedToToday() async {
        for id in selectedItems {
            if let item = items.first(where: { $0.id == id }) {
                await moveToToday(item)
            }
        }
        clearSelection()
    }

    /// Batch delete selected items
    public func deleteSelected() async {
        for id in selectedItems {
            if let item = items.first(where: { $0.id == id }) {
                await delete(item)
            }
        }
        clearSelection()
    }

    // MARK: - Private Helpers

    private func updateStatus(_ item: Item, to status: ItemStatus) async {
        var updated = item
        updated.status = status
        updated.updatedAt = Date()
        await save(updated)
    }

    private func save(_ item: Item) async {
        do {
            try await itemStorage.save(item)
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = item
            }
            showZeroInboxState = isInboxEmpty
        } catch {
            errorMessage = "Failed to save item: \(error.localizedDescription)"
        }
    }

    private func urgencyGroup(for item: Item) -> UrgencyGroup {
        // Urgent: high/urgent priority or overdue
        if item.priority >= .high {
            return .urgent
        }

        // Check due date
        if let dueDate = item.dueDate {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let itemDate = calendar.startOfDay(for: dueDate)

            if itemDate < today {
                return .urgent // Overdue
            } else if calendar.isDateInToday(dueDate) {
                return .today
            } else if let weekLater = calendar.date(byAdding: .day, value: 7, to: today),
                      itemDate <= weekLater {
                return .thisWeek
            }
        }

        // Default based on status
        if item.status == .today {
            return .today
        }

        return .later
    }
}

/// Urgency grouping for inbox items
public enum UrgencyGroup: String, CaseIterable, Identifiable {
    case urgent = "Urgent"
    case today = "Today"
    case thisWeek = "This Week"
    case later = "Later"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .urgent: return "exclamationmark.triangle.fill"
        case .today: return "sun.max.fill"
        case .thisWeek: return "calendar"
        case .later: return "clock"
        }
    }

    public var color: Color {
        switch self {
        case .urgent: return .red
        case .today: return .orange
        case .thisWeek: return .blue
        case .later: return .gray
        }
    }
}

/// Filter options for inbox
public enum InboxFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case email = "Email"
    case calendar = "Calendar"
    case tasks = "Tasks"
    case highPriority = "High Priority"

    public var id: String { rawValue }
}

/// Sort order for inbox items
public enum InboxSortOrder: String, CaseIterable, Identifiable {
    case newestFirst = "Newest First"
    case oldestFirst = "Oldest First"
    case priorityFirst = "Priority"
    case dueDate = "Due Date"

    public var id: String { rawValue }
}
