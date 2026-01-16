import XCTest
@testable import JarvisCore

final class ModelsTests: XCTestCase {

    // MARK: - User Tests

    func testUserInitialization() {
        let user = User(email: "test@example.com", displayName: "Test User")

        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertEqual(user.displayName, "Test User")
        XCTAssertNil(user.avatarURL)
        XCTAssertNil(user.lastSyncedAt)
        XCTAssertTrue(user.preferences.notificationsEnabled)
    }

    func testUserCodable() throws {
        let user = User(
            email: "test@example.com",
            displayName: "Test User",
            preferences: UserPreferences(theme: .dark)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(user)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(User.self, from: data)

        XCTAssertEqual(user, decoded)
        XCTAssertEqual(decoded.preferences.theme, .dark)
    }

    func testUserPreferencesDefaults() {
        let prefs = UserPreferences()

        XCTAssertTrue(prefs.notificationsEnabled)
        XCTAssertNil(prefs.dailyDigestTime)
        XCTAssertEqual(prefs.theme, .system)
        XCTAssertNil(prefs.defaultCalendarId)
    }

    // MARK: - Item Tests

    func testItemInitialization() {
        let userId = UUID()
        let item = Item(userId: userId, title: "Test Task")

        XCTAssertEqual(item.userId, userId)
        XCTAssertEqual(item.title, "Test Task")
        XCTAssertEqual(item.itemType, .task)
        XCTAssertEqual(item.status, .inbox)
        XCTAssertEqual(item.priority, .medium)
        XCTAssertNil(item.dueDate)
        XCTAssertTrue(item.tags.isEmpty)
    }

    func testItemCodable() throws {
        let item = Item(
            userId: UUID(),
            title: "Test Task",
            content: "Some content",
            itemType: .note,
            status: .today,
            priority: .high,
            tags: ["work", "urgent"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(item)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Item.self, from: data)

        XCTAssertEqual(item, decoded)
    }

    func testItemTypeAllCases() {
        let allTypes = ItemType.allCases
        XCTAssertEqual(allTypes.count, 5)
        XCTAssertTrue(allTypes.contains(.task))
        XCTAssertTrue(allTypes.contains(.note))
        XCTAssertTrue(allTypes.contains(.event))
        XCTAssertTrue(allTypes.contains(.reminder))
        XCTAssertTrue(allTypes.contains(.reference))
    }

    func testItemStatusAllCases() {
        let allStatuses = ItemStatus.allCases
        XCTAssertEqual(allStatuses.count, 6)
    }

    func testPriorityComparable() {
        XCTAssertTrue(Priority.low < Priority.medium)
        XCTAssertTrue(Priority.medium < Priority.high)
        XCTAssertTrue(Priority.high < Priority.urgent)
    }

    // MARK: - Memory Tests

    func testMemoryInitialization() {
        let userId = UUID()
        let memory = Memory(userId: userId, content: "User prefers morning meetings")

        XCTAssertEqual(memory.userId, userId)
        XCTAssertEqual(memory.content, "User prefers morning meetings")
        XCTAssertEqual(memory.memoryType, .fact)
        XCTAssertEqual(memory.category, .general)
        XCTAssertEqual(memory.confidence, 1.0)
        XCTAssertEqual(memory.source, .explicit)
        XCTAssertTrue(memory.isActive)
        XCTAssertEqual(memory.accessCount, 0)
        XCTAssertNil(memory.embedding)
    }

    func testMemoryCodable() throws {
        let memory = Memory(
            userId: UUID(),
            content: "Test memory",
            memoryType: .preference,
            category: .work,
            confidence: 0.85,
            source: .inferred
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(memory)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Memory.self, from: data)

        XCTAssertEqual(memory, decoded)
    }

    func testMemoryWithEmbedding() {
        let embedding: [Float] = [0.1, 0.2, 0.3, 0.4, 0.5]
        let memory = Memory(
            userId: UUID(),
            content: "Test",
            embedding: embedding
        )

        XCTAssertEqual(memory.embedding, embedding)
    }

    func testMemorySearchResult() {
        let memory = Memory(userId: UUID(), content: "Test")
        let result = MemorySearchResult(memory: memory, relevanceScore: 0.95)

        XCTAssertEqual(result.memory.content, "Test")
        XCTAssertEqual(result.relevanceScore, 0.95)
    }

    // MARK: - Action Tests

    func testActionInitialization() {
        let userId = UUID()
        let action = Action(
            userId: userId,
            actionType: .create,
            targetType: .item,
            description: "Created a new task"
        )

        XCTAssertEqual(action.userId, userId)
        XCTAssertEqual(action.actionType, .create)
        XCTAssertEqual(action.targetType, .item)
        XCTAssertEqual(action.description, "Created a new task")
        XCTAssertTrue(action.metadata.isEmpty)
    }

    func testActionCodable() throws {
        let action = Action(
            userId: UUID(),
            actionType: .complete,
            targetType: .item,
            targetId: UUID(),
            description: "Completed task",
            metadata: ["source": "swipe"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(action)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Action.self, from: data)

        XCTAssertEqual(action, decoded)
        XCTAssertEqual(decoded.metadata["source"], "swipe")
    }

    func testActionTypeAllCases() {
        let allTypes = ActionType.allCases
        XCTAssertTrue(allTypes.contains(.create))
        XCTAssertTrue(allTypes.contains(.complete))
        XCTAssertTrue(allTypes.contains(.sync))
    }

    func testActionQuery() {
        let userId = UUID()
        let query = ActionQuery(
            userId: userId,
            actionTypes: [.create, .update],
            targetTypes: [.item],
            limit: 50
        )

        XCTAssertEqual(query.userId, userId)
        XCTAssertEqual(query.actionTypes?.count, 2)
        XCTAssertEqual(query.limit, 50)
    }

    // MARK: - Syncable Tests

    func testUserSyncable() {
        let user = User(email: "test@example.com")
        XCTAssertNotNil(user.id)
        XCTAssertNotNil(user.createdAt)
        XCTAssertNotNil(user.updatedAt)
    }

    func testItemSyncable() {
        let item = Item(userId: UUID(), title: "Test")
        XCTAssertNotNil(item.id)
        XCTAssertNotNil(item.createdAt)
        XCTAssertNotNil(item.updatedAt)
    }

    func testMemorySyncable() {
        let memory = Memory(userId: UUID(), content: "Test")
        XCTAssertNotNil(memory.id)
        XCTAssertNotNil(memory.createdAt)
        XCTAssertNotNil(memory.updatedAt)
    }

    // MARK: - SyncStatus Tests

    func testSyncStatusCodable() throws {
        let status = SyncStatus.pending

        let encoder = JSONEncoder()
        let data = try encoder.encode(status)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SyncStatus.self, from: data)

        XCTAssertEqual(status, decoded)
    }
}
