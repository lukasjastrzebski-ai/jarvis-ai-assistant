import Foundation

/// High-level sync manager for coordinating sync across all entity types
public actor SyncManager {
    private let engine: SyncEngine
    private var syncState: SyncState = .idle
    private var observers: [UUID: @Sendable (SyncState) -> Void] = [:]

    public init(conflictStrategy: ConflictStrategy = .newerWins) {
        self.engine = SyncEngine(conflictStrategy: conflictStrategy)
    }

    /// Get current sync state
    public func getState() -> SyncState {
        syncState
    }

    /// Observe sync state changes
    public func observe(_ callback: @escaping @Sendable (SyncState) -> Void) -> UUID {
        let id = UUID()
        observers[id] = callback
        return id
    }

    /// Remove observer
    public func removeObserver(_ id: UUID) {
        observers.removeValue(forKey: id)
    }

    /// Perform full sync of all entity types
    public func syncAll<
        ItemLocal: SyncableStorage,
        ItemRemote: SyncableStorage,
        MemoryLocal: SyncableStorage,
        MemoryRemote: SyncableStorage
    >(
        itemLocal: ItemLocal,
        itemRemote: ItemRemote,
        memoryLocal: MemoryLocal,
        memoryRemote: MemoryRemote,
        direction: SyncDirection = .both
    ) async -> [SyncResult] where
        ItemLocal.Entity == Item,
        ItemRemote.Entity == Item,
        MemoryLocal.Entity == Memory,
        MemoryRemote.Entity == Memory
    {
        await updateState(.syncing)

        var results: [SyncResult] = []

        // Sync items
        do {
            let itemResult = try await engine.sync(
                local: itemLocal,
                remote: itemRemote,
                direction: direction
            )
            results.append(itemResult)
        } catch {
            results.append(SyncResult(errors: [.serverError(error.localizedDescription)]))
        }

        // Sync memories
        do {
            let memoryResult = try await engine.sync(
                local: memoryLocal,
                remote: memoryRemote,
                direction: direction
            )
            results.append(memoryResult)
        } catch {
            results.append(SyncResult(errors: [.serverError(error.localizedDescription)]))
        }

        // Update state based on results
        let hasErrors = results.contains { !$0.isSuccess }
        if hasErrors {
            let firstError = results.flatMap { $0.errors }.first ?? .serverError("Unknown error")
            await updateState(.failed(firstError))
        } else {
            let combinedResult = SyncResult(
                uploaded: results.reduce(0) { $0 + $1.uploaded },
                downloaded: results.reduce(0) { $0 + $1.downloaded },
                conflicts: results.flatMap { $0.conflicts },
                errors: [],
                timestamp: Date()
            )
            await updateState(.success(combinedResult))
        }

        return results
    }

    private func updateState(_ newState: SyncState) async {
        syncState = newState
        for (_, observer) in observers {
            observer(newState)
        }
    }

    /// Get last sync timestamp from engine
    public func getLastSyncTimestamp() async -> Date? {
        await engine.getLastSyncTimestamp()
    }
}

/// Sync configuration
public struct SyncConfiguration: Sendable {
    public var autoSyncEnabled: Bool
    public var autoSyncInterval: TimeInterval
    public var syncOnAppForeground: Bool
    public var syncOnNetworkReconnect: Bool
    public var conflictStrategy: ConflictStrategy
    public var maxRetries: Int

    public init(
        autoSyncEnabled: Bool = true,
        autoSyncInterval: TimeInterval = 300, // 5 minutes
        syncOnAppForeground: Bool = true,
        syncOnNetworkReconnect: Bool = true,
        conflictStrategy: ConflictStrategy = .newerWins,
        maxRetries: Int = 3
    ) {
        self.autoSyncEnabled = autoSyncEnabled
        self.autoSyncInterval = autoSyncInterval
        self.syncOnAppForeground = syncOnAppForeground
        self.syncOnNetworkReconnect = syncOnNetworkReconnect
        self.conflictStrategy = conflictStrategy
        self.maxRetries = maxRetries
    }

    public static let `default` = SyncConfiguration()
}
