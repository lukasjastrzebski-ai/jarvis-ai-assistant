import XCTest
@testable import JarvisCore

final class StorageTests: XCTestCase {

    // MARK: - InMemoryStorage Generic Tests

    func testGenericStorageSaveAndFetch() async throws {
        let storage = InMemoryStorage<User>()
        let user = User(email: "test@example.com")

        try await storage.save(user)
        let fetched = try await storage.fetch(byId: user.id)

        XCTAssertEqual(fetched?.email, "test@example.com")
    }

    func testGenericStorageFetchAll() async throws {
        let storage = InMemoryStorage<User>()
        let user1 = User(email: "user1@example.com")
        let user2 = User(email: "user2@example.com")

        try await storage.saveAll([user1, user2])
        let all = try await storage.fetchAll()

        XCTAssertEqual(all.count, 2)
    }

    func testGenericStorageDelete() async throws {
        let storage = InMemoryStorage<User>()
        let user = User(email: "test@example.com")

        try await storage.save(user)
        try await storage.delete(byId: user.id)
        let fetched = try await storage.fetch(byId: user.id)

        XCTAssertNil(fetched)
    }

    func testGenericStorageCount() async throws {
        let storage = InMemoryStorage<User>()
        let user1 = User(email: "user1@example.com")
        let user2 = User(email: "user2@example.com")

        try await storage.saveAll([user1, user2])
        let count = try await storage.count()

        XCTAssertEqual(count, 2)
    }

    func testGenericStorageDeleteAll() async throws {
        let storage = InMemoryStorage<User>()
        let user1 = User(email: "user1@example.com")
        let user2 = User(email: "user2@example.com")

        try await storage.saveAll([user1, user2])
        try await storage.deleteAll()
        let count = try await storage.count()

        XCTAssertEqual(count, 0)
    }

    // MARK: - Item Storage Tests

    func testItemStorageFetchByStatus() async throws {
        let storage = InMemoryItemStorage()
        let userId = UUID()

        let item1 = Item(userId: userId, title: "Task 1", status: .inbox)
        let item2 = Item(userId: userId, title: "Task 2", status: .today)
        let item3 = Item(userId: userId, title: "Task 3", status: .inbox)

        try await storage.saveAll([item1, item2, item3])
        let inboxItems = try await storage.fetch(byStatus: .inbox)

        XCTAssertEqual(inboxItems.count, 2)
    }

    func testItemStorageFetchByUserId() async throws {
        let storage = InMemoryItemStorage()
        let userId1 = UUID()
        let userId2 = UUID()

        let item1 = Item(userId: userId1, title: "Task 1")
        let item2 = Item(userId: userId2, title: "Task 2")
        let item3 = Item(userId: userId1, title: "Task 3")

        try await storage.saveAll([item1, item2, item3])
        let user1Items = try await storage.fetch(byUserId: userId1)

        XCTAssertEqual(user1Items.count, 2)
    }

    func testItemStorageFetchDueBefore() async throws {
        let storage = InMemoryItemStorage()
        let userId = UUID()
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let tomorrow = now.addingTimeInterval(86400)

        let item1 = Item(userId: userId, title: "Past", dueDate: yesterday)
        let item2 = Item(userId: userId, title: "Future", dueDate: tomorrow)
        let item3 = Item(userId: userId, title: "No due date")

        try await storage.saveAll([item1, item2, item3])
        let overdueItems = try await storage.fetch(dueBefore: now)

        XCTAssertEqual(overdueItems.count, 1)
        XCTAssertEqual(overdueItems.first?.title, "Past")
    }

    func testItemStorageFetchByTag() async throws {
        let storage = InMemoryItemStorage()
        let userId = UUID()

        let item1 = Item(userId: userId, title: "Task 1", tags: ["work", "urgent"])
        let item2 = Item(userId: userId, title: "Task 2", tags: ["personal"])
        let item3 = Item(userId: userId, title: "Task 3", tags: ["work"])

        try await storage.saveAll([item1, item2, item3])
        let workItems = try await storage.fetch(byTag: "work")

        XCTAssertEqual(workItems.count, 2)
    }

    // MARK: - Memory Storage Tests

    func testMemoryStorageFetchByUserId() async throws {
        let storage = InMemoryMemoryStorage()
        let userId1 = UUID()
        let userId2 = UUID()

        let memory1 = Memory(userId: userId1, content: "Memory 1")
        let memory2 = Memory(userId: userId2, content: "Memory 2")

        try await storage.saveAll([memory1, memory2])
        let user1Memories = try await storage.fetch(byUserId: userId1)

        XCTAssertEqual(user1Memories.count, 1)
    }

    func testMemoryStorageFetchByCategory() async throws {
        let storage = InMemoryMemoryStorage()
        let userId = UUID()

        let memory1 = Memory(userId: userId, content: "Work memory", category: .work)
        let memory2 = Memory(userId: userId, content: "Personal memory", category: .personal)

        try await storage.saveAll([memory1, memory2])
        let workMemories = try await storage.fetch(byCategory: .work)

        XCTAssertEqual(workMemories.count, 1)
    }

    func testMemoryStorageFetchActive() async throws {
        let storage = InMemoryMemoryStorage()
        let userId = UUID()

        let memory1 = Memory(userId: userId, content: "Active", isActive: true)
        let memory2 = Memory(userId: userId, content: "Inactive", isActive: false)

        try await storage.saveAll([memory1, memory2])
        let activeMemories = try await storage.fetchActive(byUserId: userId)

        XCTAssertEqual(activeMemories.count, 1)
        XCTAssertEqual(activeMemories.first?.content, "Active")
    }

    func testMemoryStorageSearch() async throws {
        let storage = InMemoryMemoryStorage()
        let userId = UUID()

        let memory1 = Memory(userId: userId, content: "User likes morning meetings")
        let memory2 = Memory(userId: userId, content: "User prefers dark mode")
        let memory3 = Memory(userId: userId, content: "Evening routines")

        try await storage.saveAll([memory1, memory2, memory3])
        let results = try await storage.search(query: "morning", userId: userId)

        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.first?.content.contains("morning") ?? false)
    }

    // MARK: - Action Storage Tests

    func testActionStorageFetchByQuery() async throws {
        let storage = InMemoryActionStorage()
        let userId = UUID()

        let action1 = Action(userId: userId, actionType: .create, targetType: .item, description: "Created task")
        let action2 = Action(userId: userId, actionType: .complete, targetType: .item, description: "Completed task")
        let action3 = Action(userId: userId, actionType: .login, targetType: .system, description: "User login")

        try await storage.saveAll([action1, action2, action3])

        let query = ActionQuery(userId: userId, actionTypes: [.create, .update])
        let results = try await storage.fetch(query: query)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.actionType, .create)
    }

    func testActionStorageFetchRecent() async throws {
        let storage = InMemoryActionStorage()
        let userId = UUID()

        for i in 1...10 {
            let action = Action(
                userId: userId,
                actionType: .view,
                targetType: .item,
                description: "Action \(i)",
                timestamp: Date().addingTimeInterval(Double(i))
            )
            try await storage.save(action)
        }

        let recent = try await storage.fetchRecent(userId: userId, limit: 5)

        XCTAssertEqual(recent.count, 5)
        // Should be sorted by timestamp descending
        XCTAssertEqual(recent.first?.description, "Action 10")
    }

    func testActionStorageQueryWithDateRange() async throws {
        let storage = InMemoryActionStorage()
        let userId = UUID()
        let now = Date()

        let yesterday = Action(
            userId: userId,
            actionType: .create,
            targetType: .item,
            description: "Yesterday",
            timestamp: now.addingTimeInterval(-86400)
        )
        let today = Action(
            userId: userId,
            actionType: .create,
            targetType: .item,
            description: "Today",
            timestamp: now
        )
        let tomorrow = Action(
            userId: userId,
            actionType: .create,
            targetType: .item,
            description: "Tomorrow",
            timestamp: now.addingTimeInterval(86400)
        )

        try await storage.saveAll([yesterday, today, tomorrow])

        let query = ActionQuery(
            userId: userId,
            startDate: now.addingTimeInterval(-3600),
            endDate: now.addingTimeInterval(3600)
        )
        let results = try await storage.fetch(query: query)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.description, "Today")
    }

    // MARK: - Storage Error Tests

    func testStorageErrorDescriptions() {
        let notFound = StorageError.notFound(UUID())
        XCTAssertTrue(notFound.errorDescription?.contains("not found") ?? false)

        let invalidData = StorageError.invalidData("test message")
        XCTAssertTrue(invalidData.errorDescription?.contains("test message") ?? false)
    }
}
