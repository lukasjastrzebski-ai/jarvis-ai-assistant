import Foundation

/// Sync direction for operations
public enum SyncDirection: String, Codable, Sendable {
    case upload   // Local -> Cloud
    case download // Cloud -> Local
    case both     // Bi-directional
}

/// Result of a sync operation
public struct SyncResult: Sendable {
    public let uploaded: Int
    public let downloaded: Int
    public let conflicts: [SyncConflict]
    public let errors: [SyncError]
    public let timestamp: Date

    public var isSuccess: Bool {
        errors.isEmpty
    }

    public init(
        uploaded: Int = 0,
        downloaded: Int = 0,
        conflicts: [SyncConflict] = [],
        errors: [SyncError] = [],
        timestamp: Date = Date()
    ) {
        self.uploaded = uploaded
        self.downloaded = downloaded
        self.conflicts = conflicts
        self.errors = errors
        self.timestamp = timestamp
    }
}

/// A sync conflict between local and remote versions
public struct SyncConflict: Sendable {
    public let entityId: UUID
    public let entityType: String
    public let localVersion: Date
    public let remoteVersion: Date
    public let resolution: ConflictResolution?

    public init(
        entityId: UUID,
        entityType: String,
        localVersion: Date,
        remoteVersion: Date,
        resolution: ConflictResolution? = nil
    ) {
        self.entityId = entityId
        self.entityType = entityType
        self.localVersion = localVersion
        self.remoteVersion = remoteVersion
        self.resolution = resolution
    }
}

/// How a conflict was resolved
public enum ConflictResolution: String, Codable, Sendable {
    case useLocal
    case useRemote
    case merge
    case manual
}

/// Sync-specific errors
public enum SyncError: Error, LocalizedError, Sendable {
    case networkUnavailable
    case authenticationRequired
    case serverError(String)
    case conflictUnresolved(UUID)
    case dataCorruption(String)
    case quotaExceeded
    case timeout

    public var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network is unavailable"
        case .authenticationRequired:
            return "Authentication required"
        case .serverError(let message):
            return "Server error: \(message)"
        case .conflictUnresolved(let id):
            return "Unresolved conflict for entity: \(id)"
        case .dataCorruption(let message):
            return "Data corruption: \(message)"
        case .quotaExceeded:
            return "Storage quota exceeded"
        case .timeout:
            return "Sync operation timed out"
        }
    }
}

/// A change to be synced
public struct SyncChange<T: Syncable & Sendable>: Sendable {
    public let entity: T
    public let operation: SyncOperation
    public let timestamp: Date

    public init(entity: T, operation: SyncOperation, timestamp: Date = Date()) {
        self.entity = entity
        self.operation = operation
        self.timestamp = timestamp
    }
}

/// Type of sync operation
public enum SyncOperation: String, Codable, Sendable {
    case create
    case update
    case delete
}

/// Protocol for sync-capable storage
public protocol SyncableStorage: Actor {
    associatedtype Entity: Syncable

    /// Get changes since a given timestamp
    func changesSince(_ timestamp: Date) async throws -> [SyncChange<Entity>]

    /// Apply remote changes
    func applyChanges(_ changes: [SyncChange<Entity>]) async throws

    /// Get last sync timestamp
    func lastSyncTimestamp() async -> Date?

    /// Update last sync timestamp
    func setLastSyncTimestamp(_ timestamp: Date) async
}

/// Conflict resolution strategy
public enum ConflictStrategy: Sendable {
    case localWins
    case remoteWins
    case newerWins
    case custom(@Sendable (Date, Date) -> ConflictResolution)

    public func resolve(localTime: Date, remoteTime: Date) -> ConflictResolution {
        switch self {
        case .localWins:
            return .useLocal
        case .remoteWins:
            return .useRemote
        case .newerWins:
            return localTime > remoteTime ? .useLocal : .useRemote
        case .custom(let resolver):
            return resolver(localTime, remoteTime)
        }
    }
}

/// Main sync engine for bi-directional synchronization
public actor SyncEngine {
    private var lastSyncTimestamp: Date?
    private var isSyncing: Bool = false
    private let conflictStrategy: ConflictStrategy

    public init(conflictStrategy: ConflictStrategy = .newerWins) {
        self.conflictStrategy = conflictStrategy
    }

    /// Perform a sync operation
    public func sync<Local: SyncableStorage, Remote: SyncableStorage>(
        local: Local,
        remote: Remote,
        direction: SyncDirection = .both
    ) async throws -> SyncResult where Local.Entity == Remote.Entity, Local.Entity: Sendable {
        typealias T = Local.Entity
        guard !isSyncing else {
            return SyncResult(errors: [.timeout])
        }

        isSyncing = true
        defer { isSyncing = false }

        let syncStart = Date()
        var uploaded = 0
        var downloaded = 0
        var conflicts: [SyncConflict] = []
        var errors: [SyncError] = []

        let lastSync = lastSyncTimestamp ?? Date.distantPast

        // Upload local changes
        if direction == .upload || direction == .both {
            do {
                let localChanges = try await local.changesSince(lastSync)
                try await remote.applyChanges(localChanges)
                uploaded = localChanges.count
            } catch {
                errors.append(.serverError(error.localizedDescription))
            }
        }

        // Download remote changes
        if direction == .download || direction == .both {
            do {
                let remoteChanges = try await remote.changesSince(lastSync)

                // Check for conflicts
                let localChanges = try await local.changesSince(lastSync)
                let localIds = Set(localChanges.map { $0.entity.id })

                var changesToApply: [SyncChange<T>] = []

                for change in remoteChanges {
                    if localIds.contains(change.entity.id) {
                        // Conflict detected
                        let localChange = localChanges.first { $0.entity.id == change.entity.id }!
                        let resolution = conflictStrategy.resolve(
                            localTime: localChange.timestamp,
                            remoteTime: change.timestamp
                        )

                        conflicts.append(SyncConflict(
                            entityId: change.entity.id,
                            entityType: String(describing: T.self),
                            localVersion: localChange.timestamp,
                            remoteVersion: change.timestamp,
                            resolution: resolution
                        ))

                        if resolution == .useRemote {
                            changesToApply.append(change)
                        }
                    } else {
                        changesToApply.append(change)
                    }
                }

                try await local.applyChanges(changesToApply)
                downloaded = changesToApply.count
            } catch {
                errors.append(.serverError(error.localizedDescription))
            }
        }

        // Update sync timestamp if successful
        if errors.isEmpty {
            lastSyncTimestamp = syncStart
            await local.setLastSyncTimestamp(syncStart)
            await remote.setLastSyncTimestamp(syncStart)
        }

        return SyncResult(
            uploaded: uploaded,
            downloaded: downloaded,
            conflicts: conflicts,
            errors: errors,
            timestamp: syncStart
        )
    }

    /// Get the last sync timestamp
    public func getLastSyncTimestamp() -> Date? {
        lastSyncTimestamp
    }

    /// Check if currently syncing
    public func isSyncInProgress() -> Bool {
        isSyncing
    }

    /// Force set the last sync timestamp (for testing)
    public func setLastSyncTimestamp(_ timestamp: Date?) {
        lastSyncTimestamp = timestamp
    }
}

/// Sync status for UI display
public enum SyncState: Sendable {
    case idle
    case syncing
    case success(SyncResult)
    case failed(SyncError)

    public var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    public var isSyncing: Bool {
        if case .syncing = self { return true }
        return false
    }
}
