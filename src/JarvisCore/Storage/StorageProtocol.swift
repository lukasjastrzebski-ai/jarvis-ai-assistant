import Foundation

/// Protocol for data storage operations
public protocol StorageProtocol: Actor {
    associatedtype Entity: Syncable

    /// Save an entity
    func save(_ entity: Entity) async throws

    /// Save multiple entities
    func saveAll(_ entities: [Entity]) async throws

    /// Fetch entity by ID
    func fetch(byId id: UUID) async throws -> Entity?

    /// Fetch all entities
    func fetchAll() async throws -> [Entity]

    /// Delete entity by ID
    func delete(byId id: UUID) async throws

    /// Delete all entities
    func deleteAll() async throws

    /// Count of entities
    func count() async throws -> Int
}

/// Error types for storage operations
public enum StorageError: Error, LocalizedError {
    case notFound(UUID)
    case saveFailed(Error)
    case fetchFailed(Error)
    case deleteFailed(Error)
    case invalidData(String)
    case migrationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "Entity not found: \(id)"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete: \(error.localizedDescription)"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .migrationFailed(let message):
            return "Migration failed: \(message)"
        }
    }
}

/// Protocol for item-specific queries
public protocol ItemStorageProtocol: StorageProtocol where Entity == Item {
    /// Fetch items by status
    func fetch(byStatus status: ItemStatus) async throws -> [Item]

    /// Fetch items for a specific user
    func fetch(byUserId userId: UUID) async throws -> [Item]

    /// Fetch items due before a date
    func fetch(dueBefore date: Date) async throws -> [Item]

    /// Fetch items by tag
    func fetch(byTag tag: String) async throws -> [Item]
}

/// Protocol for memory-specific queries
public protocol MemoryStorageProtocol: StorageProtocol where Entity == Memory {
    /// Fetch memories by user
    func fetch(byUserId userId: UUID) async throws -> [Memory]

    /// Fetch memories by category
    func fetch(byCategory category: MemoryCategory) async throws -> [Memory]

    /// Fetch active memories
    func fetchActive(byUserId userId: UUID) async throws -> [Memory]

    /// Search memories by content (basic text search)
    func search(query: String, userId: UUID) async throws -> [Memory]
}

/// Protocol for action-specific queries (separate from Syncable entities)
public protocol ActionStorageProtocol: Actor {
    /// Save an action
    func save(_ action: Action) async throws

    /// Save multiple actions
    func saveAll(_ actions: [Action]) async throws

    /// Fetch action by ID
    func fetch(byId id: UUID) async throws -> Action?

    /// Fetch all actions
    func fetchAll() async throws -> [Action]

    /// Delete action by ID
    func delete(byId id: UUID) async throws

    /// Delete all actions
    func deleteAll() async throws

    /// Count of actions
    func count() async throws -> Int

    /// Fetch actions by query
    func fetch(query: ActionQuery) async throws -> [Action]

    /// Fetch recent actions for a user
    func fetchRecent(userId: UUID, limit: Int) async throws -> [Action]
}
