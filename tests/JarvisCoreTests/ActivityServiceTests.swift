import XCTest
@testable import JarvisCore

final class ActivityServiceTests: XCTestCase {
    var storage: InMemoryActionStorage!
    var service: ActivityService!
    let testUserId = UUID()

    override func setUp() async throws {
        storage = InMemoryActionStorage()
        service = ActivityService(storage: storage)
    }

    // MARK: - Logging Tests

    func testLogAction() async throws {
        let action = try await service.log(
            userId: testUserId,
            actionType: .create,
            targetType: .item,
            description: "Created a task"
        )

        XCTAssertEqual(action.userId, testUserId)
        XCTAssertEqual(action.actionType, .create)
        XCTAssertEqual(action.targetType, .item)
        XCTAssertEqual(action.description, "Created a task")
    }

    func testLogCreate() async throws {
        let targetId = UUID()
        let action = try await service.logCreate(
            userId: testUserId,
            targetType: .item,
            targetId: targetId,
            description: "Created item"
        )

        XCTAssertEqual(action.actionType, .create)
        XCTAssertEqual(action.targetId, targetId)
    }

    func testLogUpdate() async throws {
        let targetId = UUID()
        let action = try await service.logUpdate(
            userId: testUserId,
            targetType: .item,
            targetId: targetId,
            description: "Updated item"
        )

        XCTAssertEqual(action.actionType, .update)
    }

    func testLogDelete() async throws {
        let targetId = UUID()
        let action = try await service.logDelete(
            userId: testUserId,
            targetType: .item,
            targetId: targetId,
            description: "Deleted item"
        )

        XCTAssertEqual(action.actionType, .delete)
    }

    func testLogItemComplete() async throws {
        let itemId = UUID()
        let action = try await service.logItemComplete(
            userId: testUserId,
            itemId: itemId,
            itemTitle: "My Task"
        )

        XCTAssertEqual(action.actionType, .complete)
        XCTAssertEqual(action.targetType, .item)
        XCTAssertEqual(action.targetId, itemId)
        XCTAssertTrue(action.description.contains("My Task"))
        XCTAssertEqual(action.metadata["title"], "My Task")
    }

    func testLogView() async throws {
        let action = try await service.logView(
            userId: testUserId,
            targetType: .item,
            description: "Viewed inbox"
        )

        XCTAssertEqual(action.actionType, .view)
    }

    func testLogSearch() async throws {
        let action = try await service.logSearch(
            userId: testUserId,
            query: "test query",
            resultCount: 5
        )

        XCTAssertEqual(action.actionType, .search)
        XCTAssertEqual(action.metadata["query"], "test query")
        XCTAssertEqual(action.metadata["resultCount"], "5")
    }

    // MARK: - Query Tests

    func testGetRecentActions() async throws {
        for i in 1...10 {
            _ = try await service.log(
                userId: testUserId,
                actionType: .view,
                targetType: .item,
                description: "Action \(i)"
            )
        }

        let recent = try await service.getRecentActions(userId: testUserId, limit: 5)

        XCTAssertEqual(recent.count, 5)
    }

    func testGetActionsForTarget() async throws {
        let targetId = UUID()

        _ = try await service.logCreate(userId: testUserId, targetType: .item, targetId: targetId, description: "Create")
        _ = try await service.logUpdate(userId: testUserId, targetType: .item, targetId: targetId, description: "Update")
        _ = try await service.logCreate(userId: testUserId, targetType: .item, targetId: UUID(), description: "Other")

        let actions = try await service.getActions(
            forTarget: targetId,
            targetType: .item,
            userId: testUserId
        )

        XCTAssertEqual(actions.count, 2)
    }

    func testGetActionsByType() async throws {
        _ = try await service.log(userId: testUserId, actionType: .create, targetType: .item, description: "Create 1")
        _ = try await service.log(userId: testUserId, actionType: .create, targetType: .item, description: "Create 2")
        _ = try await service.log(userId: testUserId, actionType: .update, targetType: .item, description: "Update")

        let creates = try await service.getActions(ofType: .create, userId: testUserId)

        XCTAssertEqual(creates.count, 2)
    }

    func testGetActionsInDateRange() async throws {
        let now = Date()

        _ = try await service.log(
            userId: testUserId,
            actionType: .view,
            targetType: .item,
            description: "Now"
        )

        let actions = try await service.getActions(
            userId: testUserId,
            from: now.addingTimeInterval(-3600),
            to: now.addingTimeInterval(3600)
        )

        XCTAssertGreaterThan(actions.count, 0)
    }

    // MARK: - Analytics Tests

    func testGetActionCounts() async throws {
        _ = try await service.log(userId: testUserId, actionType: .create, targetType: .item, description: "1")
        _ = try await service.log(userId: testUserId, actionType: .create, targetType: .item, description: "2")
        _ = try await service.log(userId: testUserId, actionType: .update, targetType: .item, description: "3")
        _ = try await service.log(userId: testUserId, actionType: .complete, targetType: .item, description: "4")

        let counts = try await service.getActionCounts(userId: testUserId)

        XCTAssertEqual(counts[.create], 2)
        XCTAssertEqual(counts[.update], 1)
        XCTAssertEqual(counts[.complete], 1)
    }

    func testGetActivitySummary() async throws {
        let now = Date()

        _ = try await service.log(userId: testUserId, actionType: .create, targetType: .item, description: "1")
        _ = try await service.log(userId: testUserId, actionType: .update, targetType: .item, description: "2")
        _ = try await service.log(userId: testUserId, actionType: .complete, targetType: .item, description: "3")
        _ = try await service.logView(userId: testUserId, targetType: .item, description: "4")
        _ = try await service.logSearch(userId: testUserId, query: "test", resultCount: 1)

        let summary = try await service.getActivitySummary(
            userId: testUserId,
            from: now.addingTimeInterval(-3600),
            to: now.addingTimeInterval(3600)
        )

        XCTAssertEqual(summary.totalActions, 5)
        XCTAssertEqual(summary.creates, 1)
        XCTAssertEqual(summary.updates, 1)
        XCTAssertEqual(summary.completes, 1)
        XCTAssertEqual(summary.views, 1)
        XCTAssertEqual(summary.searches, 1)
        XCTAssertNotNil(summary.mostActiveHour)
    }

    // MARK: - ActivitySummary Tests

    func testActivitySummaryInit() {
        let summary = ActivitySummary(
            totalActions: 100,
            creates: 20,
            updates: 30,
            completes: 15,
            views: 25,
            searches: 10,
            mostActiveHour: 14,
            startDate: Date(),
            endDate: Date()
        )

        XCTAssertEqual(summary.totalActions, 100)
        XCTAssertEqual(summary.mostActiveHour, 14)
    }
}
