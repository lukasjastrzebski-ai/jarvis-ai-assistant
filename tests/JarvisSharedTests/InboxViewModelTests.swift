import XCTest
@testable import JarvisShared
@testable import JarvisCore

@MainActor
final class InboxViewModelTests: XCTestCase {
    var storage: InMemoryItemStorage!
    var viewModel: InboxViewModel!
    let testUserId = UUID()

    override func setUp() async throws {
        storage = InMemoryItemStorage()
        viewModel = InboxViewModel(itemStorage: storage, userId: testUserId)
    }

    // MARK: - Loading Tests

    func testLoadItems() async throws {
        // Create test items
        let item1 = Item(userId: testUserId, title: "Task 1", status: .inbox)
        let item2 = Item(userId: testUserId, title: "Task 2", status: .inbox)
        try await storage.save(item1)
        try await storage.save(item2)

        await viewModel.loadItems()

        XCTAssertEqual(viewModel.items.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadItemsShowsZeroInboxState() async throws {
        await viewModel.loadItems()

        XCTAssertTrue(viewModel.showZeroInboxState)
        XCTAssertTrue(viewModel.isInboxEmpty)
    }

    // MARK: - Filtering Tests

    func testFilteredItemsAll() async throws {
        let item1 = Item(userId: testUserId, title: "Task 1", status: .inbox)
        let item2 = Item(userId: testUserId, title: "Task 2", status: .completed)
        try await storage.save(item1)
        try await storage.save(item2)

        await viewModel.loadItems()

        XCTAssertEqual(viewModel.filteredItems.count, 1) // Only inbox items
    }

    func testFilteredItemsBySourceType() async throws {
        let emailItem = Item(userId: testUserId, title: "Email", status: .inbox, sourceType: .email)
        let calendarItem = Item(userId: testUserId, title: "Calendar", status: .inbox, sourceType: .calendar)
        try await storage.save(emailItem)
        try await storage.save(calendarItem)

        await viewModel.loadItems()

        viewModel.filterType = .email
        XCTAssertEqual(viewModel.filteredItems.count, 1)
        XCTAssertEqual(viewModel.filteredItems.first?.title, "Email")

        viewModel.filterType = .calendar
        XCTAssertEqual(viewModel.filteredItems.count, 1)
        XCTAssertEqual(viewModel.filteredItems.first?.title, "Calendar")
    }

    func testFilteredItemsByPriority() async throws {
        let highPriorityItem = Item(userId: testUserId, title: "High", status: .inbox, priority: .high)
        let lowPriorityItem = Item(userId: testUserId, title: "Low", status: .inbox, priority: .low)
        try await storage.save(highPriorityItem)
        try await storage.save(lowPriorityItem)

        await viewModel.loadItems()

        viewModel.filterType = .highPriority
        XCTAssertEqual(viewModel.filteredItems.count, 1)
        XCTAssertEqual(viewModel.filteredItems.first?.title, "High")
    }

    // MARK: - Sorting Tests

    func testSortByNewestFirst() async throws {
        let oldItem = Item(
            userId: testUserId,
            title: "Old",
            status: .inbox,
            createdAt: Date().addingTimeInterval(-3600)
        )
        let newItem = Item(
            userId: testUserId,
            title: "New",
            status: .inbox,
            createdAt: Date()
        )
        try await storage.save(oldItem)
        try await storage.save(newItem)

        await viewModel.loadItems()

        viewModel.sortOrder = .newestFirst
        XCTAssertEqual(viewModel.filteredItems.first?.title, "New")
    }

    func testSortByPriority() async throws {
        let lowItem = Item(userId: testUserId, title: "Low", status: .inbox, priority: .low)
        let highItem = Item(userId: testUserId, title: "High", status: .inbox, priority: .high)
        try await storage.save(lowItem)
        try await storage.save(highItem)

        await viewModel.loadItems()

        viewModel.sortOrder = .priorityFirst
        XCTAssertEqual(viewModel.filteredItems.first?.title, "High")
    }

    // MARK: - Urgency Grouping Tests

    func testUrgencyGroupingUrgent() async throws {
        let urgentItem = Item(userId: testUserId, title: "Urgent", status: .inbox, priority: .urgent)
        try await storage.save(urgentItem)

        await viewModel.loadItems()

        let urgentGroup = viewModel.groupedItems[.urgent]
        XCTAssertNotNil(urgentGroup)
        XCTAssertEqual(urgentGroup?.count, 1)
    }

    func testUrgencyGroupingToday() async throws {
        let todayItem = Item(userId: testUserId, title: "Today", status: .inbox, dueDate: Date())
        try await storage.save(todayItem)

        await viewModel.loadItems()

        let todayGroup = viewModel.groupedItems[.today]
        XCTAssertNotNil(todayGroup)
        XCTAssertEqual(todayGroup?.count, 1)
    }

    // MARK: - Action Tests

    func testArchiveItem() async throws {
        let item = Item(userId: testUserId, title: "To Archive", status: .inbox)
        try await storage.save(item)
        await viewModel.loadItems()

        await viewModel.archive(item)

        let updated = try await storage.fetch(byId: item.id)
        XCTAssertEqual(updated?.status, .archived)
    }

    func testCompleteItem() async throws {
        let item = Item(userId: testUserId, title: "To Complete", status: .inbox)
        try await storage.save(item)
        await viewModel.loadItems()

        await viewModel.complete(item)

        let updated = try await storage.fetch(byId: item.id)
        XCTAssertEqual(updated?.status, .completed)
        XCTAssertNotNil(updated?.completedAt)
    }

    func testMoveToToday() async throws {
        let item = Item(userId: testUserId, title: "Move to Today", status: .inbox)
        try await storage.save(item)
        await viewModel.loadItems()

        await viewModel.moveToToday(item)

        let updated = try await storage.fetch(byId: item.id)
        XCTAssertEqual(updated?.status, .today)
    }

    func testSnoozeItem() async throws {
        let item = Item(userId: testUserId, title: "To Snooze", status: .inbox)
        try await storage.save(item)
        await viewModel.loadItems()

        let snoozeDate = Date().addingTimeInterval(86400) // Tomorrow
        await viewModel.snooze(item, until: snoozeDate)

        let updated = try await storage.fetch(byId: item.id)
        XCTAssertEqual(updated?.status, .scheduled)
        XCTAssertNotNil(updated?.dueDate)
    }

    func testDeleteItem() async throws {
        let item = Item(userId: testUserId, title: "To Delete", status: .inbox)
        try await storage.save(item)
        await viewModel.loadItems()

        await viewModel.delete(item)

        let deleted = try await storage.fetch(byId: item.id)
        XCTAssertNil(deleted)
        XCTAssertTrue(viewModel.isInboxEmpty)
    }

    // MARK: - Selection Tests

    func testToggleSelection() async throws {
        let item = Item(userId: testUserId, title: "Select Me", status: .inbox)
        try await storage.save(item)
        await viewModel.loadItems()

        XCTAssertFalse(viewModel.selectedItems.contains(item.id))

        viewModel.toggleSelection(item)
        XCTAssertTrue(viewModel.selectedItems.contains(item.id))

        viewModel.toggleSelection(item)
        XCTAssertFalse(viewModel.selectedItems.contains(item.id))
    }

    func testSelectAll() async throws {
        let item1 = Item(userId: testUserId, title: "Item 1", status: .inbox)
        let item2 = Item(userId: testUserId, title: "Item 2", status: .inbox)
        try await storage.save(item1)
        try await storage.save(item2)
        await viewModel.loadItems()

        viewModel.selectAll()

        XCTAssertEqual(viewModel.selectedItems.count, 2)
    }

    func testClearSelection() async throws {
        let item = Item(userId: testUserId, title: "Item", status: .inbox)
        try await storage.save(item)
        await viewModel.loadItems()

        viewModel.toggleSelection(item)
        XCTAssertEqual(viewModel.selectedItems.count, 1)

        viewModel.clearSelection()
        XCTAssertTrue(viewModel.selectedItems.isEmpty)
    }

    // MARK: - Batch Operation Tests

    func testArchiveSelected() async throws {
        let item1 = Item(userId: testUserId, title: "Item 1", status: .inbox)
        let item2 = Item(userId: testUserId, title: "Item 2", status: .inbox)
        try await storage.save(item1)
        try await storage.save(item2)
        await viewModel.loadItems()

        viewModel.selectAll()
        await viewModel.archiveSelected()

        let updated1 = try await storage.fetch(byId: item1.id)
        let updated2 = try await storage.fetch(byId: item2.id)
        XCTAssertEqual(updated1?.status, .archived)
        XCTAssertEqual(updated2?.status, .archived)
        XCTAssertTrue(viewModel.selectedItems.isEmpty)
    }

    func testMoveSelectedToToday() async throws {
        let item1 = Item(userId: testUserId, title: "Item 1", status: .inbox)
        let item2 = Item(userId: testUserId, title: "Item 2", status: .inbox)
        try await storage.save(item1)
        try await storage.save(item2)
        await viewModel.loadItems()

        viewModel.selectAll()
        await viewModel.moveSelectedToToday()

        let updated1 = try await storage.fetch(byId: item1.id)
        let updated2 = try await storage.fetch(byId: item2.id)
        XCTAssertEqual(updated1?.status, .today)
        XCTAssertEqual(updated2?.status, .today)
    }

    // MARK: - Computed Property Tests

    func testInboxCount() async throws {
        let inboxItem = Item(userId: testUserId, title: "Inbox", status: .inbox)
        let completedItem = Item(userId: testUserId, title: "Completed", status: .completed)
        try await storage.save(inboxItem)
        try await storage.save(completedItem)
        await viewModel.loadItems()

        XCTAssertEqual(viewModel.inboxCount, 1)
    }
}
