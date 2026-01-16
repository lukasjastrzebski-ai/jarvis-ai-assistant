import Foundation

/// In-memory storage implementation for testing and development
public actor InMemoryStorage<Entity: Syncable>: StorageProtocol {
    private var storage: [UUID: Entity] = [:]

    public init() {}

    public func save(_ entity: Entity) async throws {
        storage[entity.id] = entity
    }

    public func saveAll(_ entities: [Entity]) async throws {
        for entity in entities {
            storage[entity.id] = entity
        }
    }

    public func fetch(byId id: UUID) async throws -> Entity? {
        return storage[id]
    }

    public func fetchAll() async throws -> [Entity] {
        return Array(storage.values)
    }

    public func delete(byId id: UUID) async throws {
        storage.removeValue(forKey: id)
    }

    public func deleteAll() async throws {
        storage.removeAll()
    }

    public func count() async throws -> Int {
        return storage.count
    }
}

/// In-memory item storage with query support
public actor InMemoryItemStorage: ItemStorageProtocol {
    private var storage: [UUID: Item] = [:]

    public init() {}

    public func save(_ entity: Item) async throws {
        storage[entity.id] = entity
    }

    public func saveAll(_ entities: [Item]) async throws {
        for entity in entities {
            storage[entity.id] = entity
        }
    }

    public func fetch(byId id: UUID) async throws -> Item? {
        return storage[id]
    }

    public func fetchAll() async throws -> [Item] {
        return Array(storage.values)
    }

    public func delete(byId id: UUID) async throws {
        storage.removeValue(forKey: id)
    }

    public func deleteAll() async throws {
        storage.removeAll()
    }

    public func count() async throws -> Int {
        return storage.count
    }

    public func fetch(byStatus status: ItemStatus) async throws -> [Item] {
        return storage.values.filter { $0.status == status }
    }

    public func fetch(byUserId userId: UUID) async throws -> [Item] {
        return storage.values.filter { $0.userId == userId }
    }

    public func fetch(dueBefore date: Date) async throws -> [Item] {
        return storage.values.filter { item in
            guard let dueDate = item.dueDate else { return false }
            return dueDate < date
        }
    }

    public func fetch(byTag tag: String) async throws -> [Item] {
        return storage.values.filter { $0.tags.contains(tag) }
    }
}

/// In-memory memory storage with query support
public actor InMemoryMemoryStorage: MemoryStorageProtocol {
    private var storage: [UUID: Memory] = [:]

    public init() {}

    public func save(_ entity: Memory) async throws {
        storage[entity.id] = entity
    }

    public func saveAll(_ entities: [Memory]) async throws {
        for entity in entities {
            storage[entity.id] = entity
        }
    }

    public func fetch(byId id: UUID) async throws -> Memory? {
        return storage[id]
    }

    public func fetchAll() async throws -> [Memory] {
        return Array(storage.values)
    }

    public func delete(byId id: UUID) async throws {
        storage.removeValue(forKey: id)
    }

    public func deleteAll() async throws {
        storage.removeAll()
    }

    public func count() async throws -> Int {
        return storage.count
    }

    public func fetch(byUserId userId: UUID) async throws -> [Memory] {
        return storage.values.filter { $0.userId == userId }
    }

    public func fetch(byCategory category: MemoryCategory) async throws -> [Memory] {
        return storage.values.filter { $0.category == category }
    }

    public func fetchActive(byUserId userId: UUID) async throws -> [Memory] {
        return storage.values.filter { $0.userId == userId && $0.isActive }
    }

    public func search(query: String, userId: UUID) async throws -> [Memory] {
        let lowercasedQuery = query.lowercased()
        return storage.values.filter { memory in
            memory.userId == userId &&
            memory.content.lowercased().contains(lowercasedQuery)
        }
    }
}

/// In-memory action storage with query support
public actor InMemoryActionStorage: ActionStorageProtocol {
    private var storage: [UUID: Action] = [:]

    public init() {}

    public func save(_ entity: Action) async throws {
        storage[entity.id] = entity
    }

    public func saveAll(_ entities: [Action]) async throws {
        for entity in entities {
            storage[entity.id] = entity
        }
    }

    public func fetch(byId id: UUID) async throws -> Action? {
        return storage[id]
    }

    public func fetchAll() async throws -> [Action] {
        return Array(storage.values)
    }

    public func delete(byId id: UUID) async throws {
        storage.removeValue(forKey: id)
    }

    public func deleteAll() async throws {
        storage.removeAll()
    }

    public func count() async throws -> Int {
        return storage.count
    }

    public func fetch(query: ActionQuery) async throws -> [Action] {
        var results = Array(storage.values)

        if let userId = query.userId {
            results = results.filter { $0.userId == userId }
        }

        if let actionTypes = query.actionTypes {
            results = results.filter { actionTypes.contains($0.actionType) }
        }

        if let targetTypes = query.targetTypes {
            results = results.filter { targetTypes.contains($0.targetType) }
        }

        if let targetId = query.targetId {
            results = results.filter { $0.targetId == targetId }
        }

        if let startDate = query.startDate {
            results = results.filter { $0.timestamp >= startDate }
        }

        if let endDate = query.endDate {
            results = results.filter { $0.timestamp <= endDate }
        }

        // Sort by timestamp descending
        results.sort { $0.timestamp > $1.timestamp }

        if let offset = query.offset {
            results = Array(results.dropFirst(offset))
        }

        if let limit = query.limit {
            results = Array(results.prefix(limit))
        }

        return results
    }

    public func fetchRecent(userId: UUID, limit: Int) async throws -> [Action] {
        return try await fetch(query: ActionQuery(userId: userId, limit: limit))
    }
}
