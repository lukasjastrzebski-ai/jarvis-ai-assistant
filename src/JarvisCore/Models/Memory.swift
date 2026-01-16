import Foundation

/// Represents a memory entry in the Jarvis memory system
/// Memories are contextual information that Jarvis learns about the user
public struct Memory: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var userId: UUID
    public var content: String
    public var memoryType: MemoryType
    public var category: MemoryCategory
    public var confidence: Double
    public var source: MemorySource
    public var relatedItemIds: [UUID]
    public var embedding: [Float]?
    public var createdAt: Date
    public var updatedAt: Date
    public var lastAccessedAt: Date?
    public var accessCount: Int
    public var isActive: Bool

    public init(
        id: UUID = UUID(),
        userId: UUID,
        content: String,
        memoryType: MemoryType = .fact,
        category: MemoryCategory = .general,
        confidence: Double = 1.0,
        source: MemorySource = .explicit,
        relatedItemIds: [UUID] = [],
        embedding: [Float]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastAccessedAt: Date? = nil,
        accessCount: Int = 0,
        isActive: Bool = true
    ) {
        self.id = id
        self.userId = userId
        self.content = content
        self.memoryType = memoryType
        self.category = category
        self.confidence = confidence
        self.source = source
        self.relatedItemIds = relatedItemIds
        self.embedding = embedding
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastAccessedAt = lastAccessedAt
        self.accessCount = accessCount
        self.isActive = isActive
    }
}

/// Type of memory
public enum MemoryType: String, Codable, CaseIterable, Sendable {
    case fact        // A fact about the user (e.g., "prefers morning meetings")
    case preference  // A preference (e.g., "likes dark mode")
    case context     // Contextual info (e.g., "working on project X")
    case routine     // A routine or habit
    case relationship // Information about contacts/relationships
}

/// Category for organizing memories
public enum MemoryCategory: String, Codable, CaseIterable, Sendable {
    case general
    case work
    case personal
    case health
    case finance
    case travel
    case social
    case learning
}

/// How the memory was acquired
public enum MemorySource: String, Codable, Sendable {
    case explicit    // User explicitly told Jarvis
    case inferred    // Jarvis inferred from behavior
    case imported    // Imported from external source
    case corrected   // User corrected a previous inference
}

/// A search result for memory queries
public struct MemorySearchResult: Sendable {
    public let memory: Memory
    public let relevanceScore: Double

    public init(memory: Memory, relevanceScore: Double) {
        self.memory = memory
        self.relevanceScore = relevanceScore
    }
}
