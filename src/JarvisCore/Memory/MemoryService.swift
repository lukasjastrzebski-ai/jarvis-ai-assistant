import Foundation

/// Service for managing user memories with semantic search capabilities
public actor MemoryService {
    private let storage: any MemoryStorageProtocol
    private var embeddingCache: [UUID: [Float]] = [:]

    public init(storage: any MemoryStorageProtocol) {
        self.storage = storage
    }

    // MARK: - CRUD Operations

    /// Create a new memory
    public func createMemory(
        userId: UUID,
        content: String,
        type: MemoryType = .fact,
        category: MemoryCategory = .general,
        source: MemorySource = .explicit,
        relatedItemIds: [UUID] = []
    ) async throws -> Memory {
        var memory = Memory(
            userId: userId,
            content: content,
            memoryType: type,
            category: category,
            source: source,
            relatedItemIds: relatedItemIds
        )

        // Generate embedding if content is substantial
        if content.count > 10 {
            memory = Memory(
                id: memory.id,
                userId: memory.userId,
                content: memory.content,
                memoryType: memory.memoryType,
                category: memory.category,
                confidence: memory.confidence,
                source: memory.source,
                relatedItemIds: memory.relatedItemIds,
                embedding: generateLocalEmbedding(for: content),
                createdAt: memory.createdAt,
                updatedAt: memory.updatedAt,
                lastAccessedAt: memory.lastAccessedAt,
                accessCount: memory.accessCount,
                isActive: memory.isActive
            )
        }

        try await storage.save(memory)
        return memory
    }

    /// Get a memory by ID
    public func getMemory(byId id: UUID) async throws -> Memory? {
        guard var memory = try await storage.fetch(byId: id) else {
            return nil
        }

        // Update access tracking
        memory = Memory(
            id: memory.id,
            userId: memory.userId,
            content: memory.content,
            memoryType: memory.memoryType,
            category: memory.category,
            confidence: memory.confidence,
            source: memory.source,
            relatedItemIds: memory.relatedItemIds,
            embedding: memory.embedding,
            createdAt: memory.createdAt,
            updatedAt: memory.updatedAt,
            lastAccessedAt: Date(),
            accessCount: memory.accessCount + 1,
            isActive: memory.isActive
        )

        try await storage.save(memory)
        return memory
    }

    /// Get all memories for a user
    public func getMemories(forUser userId: UUID) async throws -> [Memory] {
        return try await storage.fetch(byUserId: userId)
    }

    /// Get active memories for a user
    public func getActiveMemories(forUser userId: UUID) async throws -> [Memory] {
        return try await storage.fetchActive(byUserId: userId)
    }

    /// Update a memory's confidence score
    public func updateConfidence(memoryId: UUID, confidence: Double) async throws {
        guard var memory = try await storage.fetch(byId: memoryId) else {
            throw MemoryError.notFound(memoryId)
        }

        memory = Memory(
            id: memory.id,
            userId: memory.userId,
            content: memory.content,
            memoryType: memory.memoryType,
            category: memory.category,
            confidence: min(1.0, max(0.0, confidence)),
            source: memory.source,
            relatedItemIds: memory.relatedItemIds,
            embedding: memory.embedding,
            createdAt: memory.createdAt,
            updatedAt: Date(),
            lastAccessedAt: memory.lastAccessedAt,
            accessCount: memory.accessCount,
            isActive: memory.isActive
        )

        try await storage.save(memory)
    }

    /// Deactivate a memory (soft delete)
    public func deactivateMemory(memoryId: UUID) async throws {
        guard var memory = try await storage.fetch(byId: memoryId) else {
            throw MemoryError.notFound(memoryId)
        }

        memory = Memory(
            id: memory.id,
            userId: memory.userId,
            content: memory.content,
            memoryType: memory.memoryType,
            category: memory.category,
            confidence: memory.confidence,
            source: memory.source,
            relatedItemIds: memory.relatedItemIds,
            embedding: memory.embedding,
            createdAt: memory.createdAt,
            updatedAt: Date(),
            lastAccessedAt: memory.lastAccessedAt,
            accessCount: memory.accessCount,
            isActive: false
        )

        try await storage.save(memory)
    }

    // MARK: - Search Operations

    /// Basic text search
    public func search(query: String, userId: UUID) async throws -> [Memory] {
        return try await storage.search(query: query, userId: userId)
    }

    /// Semantic search using embeddings
    public func semanticSearch(
        query: String,
        userId: UUID,
        limit: Int = 10,
        minSimilarity: Float = 0.5
    ) async throws -> [MemorySearchResult] {
        let queryEmbedding = generateLocalEmbedding(for: query)
        let memories = try await storage.fetchActive(byUserId: userId)

        var results: [MemorySearchResult] = []

        for memory in memories {
            guard let embedding = memory.embedding else { continue }

            let similarity = cosineSimilarity(queryEmbedding, embedding)
            if similarity >= minSimilarity {
                results.append(MemorySearchResult(memory: memory, relevanceScore: Double(similarity)))
            }
        }

        // Sort by relevance descending
        results.sort { $0.relevanceScore > $1.relevanceScore }

        return Array(results.prefix(limit))
    }

    /// Get memories by category
    public func getMemories(byCategory category: MemoryCategory, userId: UUID) async throws -> [Memory] {
        let all = try await storage.fetch(byUserId: userId)
        return all.filter { $0.category == category && $0.isActive }
    }

    /// Get memories by type
    public func getMemories(byType type: MemoryType, userId: UUID) async throws -> [Memory] {
        let all = try await storage.fetch(byUserId: userId)
        return all.filter { $0.memoryType == type && $0.isActive }
    }

    // MARK: - Embedding Operations

    /// Generate a simple local embedding (bag of words approach)
    /// In production, this would call an embedding API
    private func generateLocalEmbedding(for text: String) -> [Float] {
        // Simple bag-of-words embedding for local development
        // Production would use OpenAI ada-002 or similar
        let words = text.lowercased()
            .components(separatedBy: .alphanumerics.inverted)
            .filter { !$0.isEmpty }

        // Create a simple hash-based embedding
        var embedding = [Float](repeating: 0, count: 256)
        for word in words {
            let hash = abs(word.hashValue)
            let index = hash % 256
            embedding[index] += 1.0
        }

        // Normalize
        let magnitude = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
        if magnitude > 0 {
            embedding = embedding.map { $0 / magnitude }
        }

        return embedding
    }

    /// Calculate cosine similarity between two embeddings
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }

        var dotProduct: Float = 0
        var magnitudeA: Float = 0
        var magnitudeB: Float = 0

        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            magnitudeA += a[i] * a[i]
            magnitudeB += b[i] * b[i]
        }

        let magnitude = sqrt(magnitudeA) * sqrt(magnitudeB)
        return magnitude > 0 ? dotProduct / magnitude : 0
    }
}

/// Memory-specific errors
public enum MemoryError: Error, LocalizedError {
    case notFound(UUID)
    case embeddingFailed(String)
    case searchFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "Memory not found: \(id)"
        case .embeddingFailed(let message):
            return "Embedding generation failed: \(message)"
        case .searchFailed(let message):
            return "Search failed: \(message)"
        }
    }
}
