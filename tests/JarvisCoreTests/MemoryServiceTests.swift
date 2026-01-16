import XCTest
@testable import JarvisCore

final class MemoryServiceTests: XCTestCase {
    var storage: InMemoryMemoryStorage!
    var service: MemoryService!
    let testUserId = UUID()

    override func setUp() async throws {
        storage = InMemoryMemoryStorage()
        service = MemoryService(storage: storage)
    }

    // MARK: - CRUD Tests

    func testCreateMemory() async throws {
        let memory = try await service.createMemory(
            userId: testUserId,
            content: "User prefers morning meetings",
            type: .preference,
            category: .work
        )

        XCTAssertEqual(memory.userId, testUserId)
        XCTAssertEqual(memory.content, "User prefers morning meetings")
        XCTAssertEqual(memory.memoryType, .preference)
        XCTAssertEqual(memory.category, .work)
        XCTAssertTrue(memory.isActive)
    }

    func testCreateMemoryGeneratesEmbedding() async throws {
        let memory = try await service.createMemory(
            userId: testUserId,
            content: "This is a long enough content to generate an embedding",
            type: .fact
        )

        XCTAssertNotNil(memory.embedding)
        XCTAssertEqual(memory.embedding?.count, 256) // Our local embedding size
    }

    func testGetMemoryUpdatesAccessCount() async throws {
        let created = try await service.createMemory(
            userId: testUserId,
            content: "Test memory"
        )

        let fetched = try await service.getMemory(byId: created.id)

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.accessCount, 1)
        XCTAssertNotNil(fetched?.lastAccessedAt)
    }

    func testGetMemoriesForUser() async throws {
        _ = try await service.createMemory(userId: testUserId, content: "Memory 1")
        _ = try await service.createMemory(userId: testUserId, content: "Memory 2")
        _ = try await service.createMemory(userId: UUID(), content: "Other user memory")

        let memories = try await service.getMemories(forUser: testUserId)

        XCTAssertEqual(memories.count, 2)
    }

    func testUpdateConfidence() async throws {
        let memory = try await service.createMemory(
            userId: testUserId,
            content: "Test memory"
        )

        try await service.updateConfidence(memoryId: memory.id, confidence: 0.75)

        let updated = try await service.getMemory(byId: memory.id)
        XCTAssertEqual(updated?.confidence, 0.75)
    }

    func testUpdateConfidenceClamps() async throws {
        let memory = try await service.createMemory(
            userId: testUserId,
            content: "Test memory"
        )

        try await service.updateConfidence(memoryId: memory.id, confidence: 1.5)
        var updated = try await service.getMemory(byId: memory.id)
        XCTAssertEqual(updated?.confidence, 1.0)

        try await service.updateConfidence(memoryId: memory.id, confidence: -0.5)
        updated = try await service.getMemory(byId: memory.id)
        XCTAssertEqual(updated?.confidence, 0.0)
    }

    func testDeactivateMemory() async throws {
        let memory = try await service.createMemory(
            userId: testUserId,
            content: "Test memory"
        )

        try await service.deactivateMemory(memoryId: memory.id)

        let deactivated = try await service.getMemory(byId: memory.id)
        XCTAssertFalse(deactivated?.isActive ?? true)
    }

    func testGetActiveMemoriesExcludesDeactivated() async throws {
        let active = try await service.createMemory(userId: testUserId, content: "Active")
        let toDeactivate = try await service.createMemory(userId: testUserId, content: "To deactivate")

        try await service.deactivateMemory(memoryId: toDeactivate.id)

        let activeMemories = try await service.getActiveMemories(forUser: testUserId)

        XCTAssertEqual(activeMemories.count, 1)
        XCTAssertEqual(activeMemories.first?.id, active.id)
    }

    // MARK: - Search Tests

    func testBasicSearch() async throws {
        _ = try await service.createMemory(userId: testUserId, content: "User likes coffee in the morning")
        _ = try await service.createMemory(userId: testUserId, content: "User prefers tea in the afternoon")
        _ = try await service.createMemory(userId: testUserId, content: "User exercises daily")

        let results = try await service.search(query: "morning", userId: testUserId)

        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.first?.content.contains("morning") ?? false)
    }

    func testSemanticSearch() async throws {
        _ = try await service.createMemory(userId: testUserId, content: "User likes coffee every morning")
        _ = try await service.createMemory(userId: testUserId, content: "User prefers working from home")
        _ = try await service.createMemory(userId: testUserId, content: "User enjoys reading books")

        let results = try await service.semanticSearch(
            query: "coffee morning routine",
            userId: testUserId,
            limit: 5,
            minSimilarity: 0.1
        )

        // The coffee/morning memory should rank higher
        XCTAssertGreaterThan(results.count, 0)
    }

    func testGetMemoriesByCategory() async throws {
        _ = try await service.createMemory(userId: testUserId, content: "Work memory", category: .work)
        _ = try await service.createMemory(userId: testUserId, content: "Personal memory", category: .personal)

        let workMemories = try await service.getMemories(byCategory: .work, userId: testUserId)

        XCTAssertEqual(workMemories.count, 1)
        XCTAssertEqual(workMemories.first?.category, .work)
    }

    func testGetMemoriesByType() async throws {
        _ = try await service.createMemory(userId: testUserId, content: "A fact", type: .fact)
        _ = try await service.createMemory(userId: testUserId, content: "A preference", type: .preference)

        let facts = try await service.getMemories(byType: .fact, userId: testUserId)

        XCTAssertEqual(facts.count, 1)
        XCTAssertEqual(facts.first?.memoryType, .fact)
    }

    // MARK: - Error Tests

    func testUpdateConfidenceNotFound() async throws {
        do {
            try await service.updateConfidence(memoryId: UUID(), confidence: 0.5)
            XCTFail("Should throw error")
        } catch let error as MemoryError {
            if case .notFound = error {
                // Expected
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    func testMemoryErrorDescriptions() {
        let notFound = MemoryError.notFound(UUID())
        XCTAssertTrue(notFound.errorDescription?.contains("not found") ?? false)

        let embeddingFailed = MemoryError.embeddingFailed("test")
        XCTAssertTrue(embeddingFailed.errorDescription?.contains("test") ?? false)
    }
}
