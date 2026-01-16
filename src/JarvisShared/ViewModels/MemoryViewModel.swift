import SwiftUI
import JarvisCore

/// View model for the Memory System
@MainActor
public class MemoryViewModel: ObservableObject {
    // MARK: - Published State

    @Published public var memories: [Memory] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var searchQuery: String = ""
    @Published public var filterCategory: MemoryCategory?
    @Published public var filterType: MemoryType?
    @Published public var selectedMemory: Memory?
    @Published public var showMemoryDetail: Bool = false
    @Published public var showAddMemory: Bool = false
    @Published public var searchResults: [MemorySearchResult] = []
    @Published public var isSearching: Bool = false

    // MARK: - Dependencies

    private let memoryService: MemoryService
    private let userId: UUID

    // MARK: - Computed Properties

    /// Filtered memories
    public var filteredMemories: [Memory] {
        var result = memories.filter { $0.isActive }

        // Filter by category
        if let category = filterCategory {
            result = result.filter { $0.category == category }
        }

        // Filter by type
        if let type = filterType {
            result = result.filter { $0.memoryType == type }
        }

        // Sort by recent access
        result.sort { ($0.lastAccessedAt ?? $0.createdAt) > ($1.lastAccessedAt ?? $1.createdAt) }

        return result
    }

    /// Memories grouped by category
    public var groupedMemories: [MemoryCategory: [Memory]] {
        var groups: [MemoryCategory: [Memory]] = [:]
        for memory in filteredMemories {
            groups[memory.category, default: []].append(memory)
        }
        return groups
    }

    /// Total memory count
    public var totalCount: Int {
        memories.filter { $0.isActive }.count
    }

    // MARK: - Initialization

    public init(memoryService: MemoryService, userId: UUID) {
        self.memoryService = memoryService
        self.userId = userId
    }

    // MARK: - Actions

    /// Load all memories
    public func loadMemories() async {
        isLoading = true
        errorMessage = nil

        do {
            memories = try await memoryService.getMemories(forUser: userId)
        } catch {
            errorMessage = "Failed to load memories: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Refresh memories
    public func refresh() async {
        await loadMemories()
    }

    /// Search memories
    public func search() async {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        do {
            searchResults = try await memoryService.semanticSearch(
                query: searchQuery,
                userId: userId,
                limit: 20,
                minSimilarity: 0.1
            )
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }

        isSearching = false
    }

    /// Create a new memory
    public func createMemory(
        content: String,
        type: MemoryType = .fact,
        category: MemoryCategory = .general
    ) async {
        do {
            let memory = try await memoryService.createMemory(
                userId: userId,
                content: content,
                type: type,
                category: category
            )
            memories.append(memory)
        } catch {
            errorMessage = "Failed to create memory: \(error.localizedDescription)"
        }
    }

    /// Update memory confidence
    public func updateConfidence(_ memory: Memory, confidence: Double) async {
        do {
            try await memoryService.updateConfidence(memoryId: memory.id, confidence: confidence)
            if let index = memories.firstIndex(where: { $0.id == memory.id }) {
                var updated = memories[index]
                updated.confidence = confidence
                memories[index] = updated
            }
        } catch {
            errorMessage = "Failed to update confidence: \(error.localizedDescription)"
        }
    }

    /// Deactivate a memory
    public func deactivate(_ memory: Memory) async {
        do {
            try await memoryService.deactivateMemory(memoryId: memory.id)
            if let index = memories.firstIndex(where: { $0.id == memory.id }) {
                var updated = memories[index]
                updated.isActive = false
                memories[index] = updated
            }
        } catch {
            errorMessage = "Failed to deactivate memory: \(error.localizedDescription)"
        }
    }

    /// Select a memory for detail view
    public func selectMemory(_ memory: Memory) {
        selectedMemory = memory
        showMemoryDetail = true
    }

    /// Clear selection
    public func clearSelection() {
        selectedMemory = nil
        showMemoryDetail = false
    }

    /// Clear filters
    public func clearFilters() {
        filterCategory = nil
        filterType = nil
        searchQuery = ""
        searchResults = []
    }
}
