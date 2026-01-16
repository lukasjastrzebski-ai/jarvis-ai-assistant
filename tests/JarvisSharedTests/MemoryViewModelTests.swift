import XCTest
@testable import JarvisShared
@testable import JarvisCore

@MainActor
final class MemoryViewModelTests: XCTestCase {
    var storage: InMemoryMemoryStorage!
    var memoryService: MemoryService!
    var viewModel: MemoryViewModel!
    let testUserId = UUID()

    override func setUp() async throws {
        storage = InMemoryMemoryStorage()
        memoryService = MemoryService(storage: storage)
        viewModel = MemoryViewModel(memoryService: memoryService, userId: testUserId)
    }

    // MARK: - Loading Tests

    func testLoadMemories() async throws {
        // Create test memories
        _ = try await memoryService.createMemory(
            userId: testUserId,
            content: "User prefers morning meetings",
            type: .preference,
            category: .work
        )
        _ = try await memoryService.createMemory(
            userId: testUserId,
            content: "User likes coffee",
            type: .fact,
            category: .personal
        )

        await viewModel.loadMemories()

        XCTAssertEqual(viewModel.memories.count, 2)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadMemoriesEmpty() async throws {
        await viewModel.loadMemories()

        XCTAssertTrue(viewModel.memories.isEmpty)
    }

    // MARK: - Filtering Tests

    func testFilteredMemoriesExcludesInactive() async throws {
        let memory = try await memoryService.createMemory(
            userId: testUserId,
            content: "Test memory"
        )
        try await memoryService.deactivateMemory(memoryId: memory.id)

        await viewModel.loadMemories()

        XCTAssertTrue(viewModel.filteredMemories.isEmpty)
    }

    func testFilteredMemoriesByCategory() async throws {
        _ = try await memoryService.createMemory(
            userId: testUserId,
            content: "Work memory",
            category: .work
        )
        _ = try await memoryService.createMemory(
            userId: testUserId,
            content: "Personal memory",
            category: .personal
        )

        await viewModel.loadMemories()

        viewModel.filterCategory = .work
        XCTAssertEqual(viewModel.filteredMemories.count, 1)
        XCTAssertEqual(viewModel.filteredMemories.first?.category, .work)
    }

    func testFilteredMemoriesByType() async throws {
        _ = try await memoryService.createMemory(
            userId: testUserId,
            content: "A fact",
            type: .fact
        )
        _ = try await memoryService.createMemory(
            userId: testUserId,
            content: "A preference",
            type: .preference
        )

        await viewModel.loadMemories()

        viewModel.filterType = .fact
        XCTAssertEqual(viewModel.filteredMemories.count, 1)
        XCTAssertEqual(viewModel.filteredMemories.first?.memoryType, .fact)
    }

    // MARK: - Grouping Tests

    func testGroupedMemoriesByCategory() async throws {
        _ = try await memoryService.createMemory(
            userId: testUserId,
            content: "Work 1",
            category: .work
        )
        _ = try await memoryService.createMemory(
            userId: testUserId,
            content: "Work 2",
            category: .work
        )
        _ = try await memoryService.createMemory(
            userId: testUserId,
            content: "Personal",
            category: .personal
        )

        await viewModel.loadMemories()

        XCTAssertEqual(viewModel.groupedMemories[.work]?.count, 2)
        XCTAssertEqual(viewModel.groupedMemories[.personal]?.count, 1)
    }

    // MARK: - Search Tests

    func testSearch() async throws {
        _ = try await memoryService.createMemory(
            userId: testUserId,
            content: "User prefers morning meetings and coffee"
        )
        _ = try await memoryService.createMemory(
            userId: testUserId,
            content: "User likes afternoon walks"
        )

        await viewModel.loadMemories()

        viewModel.searchQuery = "morning coffee"
        await viewModel.search()

        // Should find results with low similarity threshold
        XCTAssertFalse(viewModel.isSearching)
    }

    func testSearchEmptyQuery() async throws {
        viewModel.searchQuery = ""
        await viewModel.search()

        XCTAssertTrue(viewModel.searchResults.isEmpty)
    }

    // MARK: - Create Tests

    func testCreateMemory() async throws {
        await viewModel.createMemory(
            content: "New memory",
            type: .fact,
            category: .work
        )

        XCTAssertEqual(viewModel.memories.count, 1)
        XCTAssertEqual(viewModel.memories.first?.content, "New memory")
        XCTAssertEqual(viewModel.memories.first?.memoryType, .fact)
        XCTAssertEqual(viewModel.memories.first?.category, .work)
    }

    // MARK: - Update Tests

    func testUpdateConfidence() async throws {
        let memory = try await memoryService.createMemory(
            userId: testUserId,
            content: "Test memory"
        )

        await viewModel.loadMemories()
        await viewModel.updateConfidence(memory, confidence: 0.75)

        let updated = viewModel.memories.first { $0.id == memory.id }
        XCTAssertEqual(updated?.confidence, 0.75)
    }

    // MARK: - Deactivate Tests

    func testDeactivateMemory() async throws {
        let memory = try await memoryService.createMemory(
            userId: testUserId,
            content: "Test memory"
        )

        await viewModel.loadMemories()
        await viewModel.deactivate(memory)

        let updated = viewModel.memories.first { $0.id == memory.id }
        XCTAssertFalse(updated?.isActive ?? true)
    }

    // MARK: - Selection Tests

    func testSelectMemory() async throws {
        let memory = try await memoryService.createMemory(
            userId: testUserId,
            content: "Test memory"
        )

        await viewModel.loadMemories()
        viewModel.selectMemory(memory)

        XCTAssertEqual(viewModel.selectedMemory?.id, memory.id)
        XCTAssertTrue(viewModel.showMemoryDetail)
    }

    func testClearSelection() async throws {
        let memory = try await memoryService.createMemory(
            userId: testUserId,
            content: "Test memory"
        )

        await viewModel.loadMemories()
        viewModel.selectMemory(memory)
        viewModel.clearSelection()

        XCTAssertNil(viewModel.selectedMemory)
        XCTAssertFalse(viewModel.showMemoryDetail)
    }

    // MARK: - Filter Clear Tests

    func testClearFilters() async throws {
        viewModel.filterCategory = .work
        viewModel.filterType = .fact
        viewModel.searchQuery = "test"

        viewModel.clearFilters()

        XCTAssertNil(viewModel.filterCategory)
        XCTAssertNil(viewModel.filterType)
        XCTAssertTrue(viewModel.searchQuery.isEmpty)
        XCTAssertTrue(viewModel.searchResults.isEmpty)
    }

    // MARK: - Count Tests

    func testTotalCount() async throws {
        _ = try await memoryService.createMemory(userId: testUserId, content: "1")
        _ = try await memoryService.createMemory(userId: testUserId, content: "2")

        await viewModel.loadMemories()

        XCTAssertEqual(viewModel.totalCount, 2)
    }

    func testTotalCountExcludesInactive() async throws {
        _ = try await memoryService.createMemory(userId: testUserId, content: "Active")
        let inactive = try await memoryService.createMemory(userId: testUserId, content: "Inactive")
        try await memoryService.deactivateMemory(memoryId: inactive.id)

        await viewModel.loadMemories()

        XCTAssertEqual(viewModel.totalCount, 1)
    }
}
