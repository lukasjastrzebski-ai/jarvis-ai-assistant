import XCTest
@testable import JarvisShared
@testable import JarvisCore

@MainActor
final class ActivityLogViewModelTests: XCTestCase {
    var storage: InMemoryActionStorage!
    var activityService: ActivityService!
    var viewModel: ActivityLogViewModel!
    let testUserId = UUID()

    override func setUp() async throws {
        storage = InMemoryActionStorage()
        activityService = ActivityService(storage: storage)
        viewModel = ActivityLogViewModel(activityService: activityService, userId: testUserId)
    }

    // MARK: - Loading Tests

    func testLoadActions() async throws {
        // Create test actions
        _ = try await activityService.log(
            userId: testUserId,
            actionType: .create,
            targetType: .item,
            description: "Created item"
        )
        _ = try await activityService.log(
            userId: testUserId,
            actionType: .update,
            targetType: .item,
            description: "Updated item"
        )

        viewModel.dateRange = .allTime
        await viewModel.loadActions()

        XCTAssertEqual(viewModel.actions.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadActionsEmpty() async throws {
        await viewModel.loadActions()

        XCTAssertTrue(viewModel.actions.isEmpty)
    }

    // MARK: - Filtering Tests

    func testFilteredActionsAll() async throws {
        _ = try await activityService.log(userId: testUserId, actionType: .create, targetType: .item, description: "1")
        _ = try await activityService.log(userId: testUserId, actionType: .update, targetType: .item, description: "2")

        viewModel.dateRange = .allTime
        await viewModel.loadActions()

        viewModel.filterType = .all
        XCTAssertEqual(viewModel.filteredActions.count, 2)
    }

    func testFilteredActionsByType() async throws {
        _ = try await activityService.log(userId: testUserId, actionType: .create, targetType: .item, description: "1")
        _ = try await activityService.log(userId: testUserId, actionType: .create, targetType: .item, description: "2")
        _ = try await activityService.log(userId: testUserId, actionType: .update, targetType: .item, description: "3")

        viewModel.dateRange = .allTime
        await viewModel.loadActions()

        viewModel.filterType = .creates
        XCTAssertEqual(viewModel.filteredActions.count, 2)

        viewModel.filterType = .updates
        XCTAssertEqual(viewModel.filteredActions.count, 1)
    }

    func testFilteredActionsCompletes() async throws {
        _ = try await activityService.log(userId: testUserId, actionType: .complete, targetType: .item, description: "1")
        _ = try await activityService.log(userId: testUserId, actionType: .create, targetType: .item, description: "2")

        viewModel.dateRange = .allTime
        await viewModel.loadActions()

        viewModel.filterType = .completes
        XCTAssertEqual(viewModel.filteredActions.count, 1)
    }

    // MARK: - Grouping Tests

    func testGroupedActionsByDate() async throws {
        _ = try await activityService.log(userId: testUserId, actionType: .create, targetType: .item, description: "1")
        _ = try await activityService.log(userId: testUserId, actionType: .update, targetType: .item, description: "2")

        viewModel.dateRange = .allTime
        await viewModel.loadActions()

        XCTAssertFalse(viewModel.groupedActions.isEmpty)
        // All actions are today, so should be one group
        XCTAssertEqual(viewModel.groupedActions.count, 1)
        XCTAssertEqual(viewModel.groupedActions.first?.actions.count, 2)
    }

    // MARK: - Summary Tests

    func testSummaryStatistics() async throws {
        _ = try await activityService.log(userId: testUserId, actionType: .create, targetType: .item, description: "1")
        _ = try await activityService.log(userId: testUserId, actionType: .update, targetType: .item, description: "2")
        _ = try await activityService.log(userId: testUserId, actionType: .complete, targetType: .item, description: "3")

        viewModel.dateRange = .allTime
        await viewModel.loadActions()

        let summary = viewModel.summary
        XCTAssertNotNil(summary)
        XCTAssertEqual(summary?.totalActions, 3)
        XCTAssertEqual(summary?.creates, 1)
        XCTAssertEqual(summary?.updates, 1)
        XCTAssertEqual(summary?.completes, 1)
    }

    func testSummaryNilWhenEmpty() async throws {
        await viewModel.loadActions()

        XCTAssertNil(viewModel.summary)
    }

    // MARK: - Selection Tests

    func testSelectAction() async throws {
        let action = try await activityService.log(
            userId: testUserId,
            actionType: .create,
            targetType: .item,
            description: "Test"
        )

        viewModel.dateRange = .allTime
        await viewModel.loadActions()

        viewModel.selectAction(action)

        XCTAssertEqual(viewModel.selectedAction?.id, action.id)
        XCTAssertTrue(viewModel.showActionDetail)
    }

    func testClearSelection() async throws {
        let action = try await activityService.log(
            userId: testUserId,
            actionType: .create,
            targetType: .item,
            description: "Test"
        )

        viewModel.dateRange = .allTime
        await viewModel.loadActions()

        viewModel.selectAction(action)
        viewModel.clearSelection()

        XCTAssertNil(viewModel.selectedAction)
        XCTAssertFalse(viewModel.showActionDetail)
    }

    // MARK: - Export Tests

    func testExportActions() async throws {
        _ = try await activityService.log(userId: testUserId, actionType: .create, targetType: .item, description: "1")

        viewModel.dateRange = .allTime
        await viewModel.loadActions()

        let data = viewModel.exportActions()
        XCTAssertNotNil(data)

        // Verify it's valid JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode([Action].self, from: data!)
        XCTAssertEqual(decoded.count, 1)
    }

    // MARK: - Date Range Tests

    func testDateRangeToday() async throws {
        viewModel.dateRange = .today
        // Just verify it doesn't crash
        await viewModel.loadActions()
        XCTAssertFalse(viewModel.isLoading)
    }

    func testDateRangeThisWeek() async throws {
        viewModel.dateRange = .thisWeek
        await viewModel.loadActions()
        XCTAssertFalse(viewModel.isLoading)
    }

    func testDateRangeThisMonth() async throws {
        viewModel.dateRange = .thisMonth
        await viewModel.loadActions()
        XCTAssertFalse(viewModel.isLoading)
    }

    func testDateRangeAllTime() async throws {
        viewModel.dateRange = .allTime
        await viewModel.loadActions()
        XCTAssertFalse(viewModel.isLoading)
    }
}
