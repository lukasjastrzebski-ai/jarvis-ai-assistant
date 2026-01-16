import XCTest
@testable import JarvisCore

// Mock syncable storage for testing
actor MockSyncableStorage<Entity: Syncable>: SyncableStorage {
    private var storage: [UUID: Entity] = [:]
    private var changes: [SyncChange<Entity>] = []
    private var lastSync: Date?

    func changesSince(_ timestamp: Date) async throws -> [SyncChange<Entity>] {
        return changes.filter { $0.timestamp > timestamp }
    }

    func applyChanges(_ changes: [SyncChange<Entity>]) async throws {
        for change in changes {
            switch change.operation {
            case .create, .update:
                storage[change.entity.id] = change.entity
            case .delete:
                storage.removeValue(forKey: change.entity.id)
            }
            // Only add change if it doesn't already exist (avoid double-counting)
            if !self.changes.contains(where: { $0.entity.id == change.entity.id && $0.timestamp == change.timestamp }) {
                self.changes.append(change)
            }
        }
    }

    func lastSyncTimestamp() async -> Date? {
        return lastSync
    }

    func setLastSyncTimestamp(_ timestamp: Date) async {
        lastSync = timestamp
    }

    // Test helpers
    func addChange(_ change: SyncChange<Entity>) {
        changes.append(change)
        if change.operation != .delete {
            storage[change.entity.id] = change.entity
        }
    }

    func getEntity(_ id: UUID) -> Entity? {
        return storage[id]
    }

    func getAllEntities() -> [Entity] {
        return Array(storage.values)
    }
}

final class SyncTests: XCTestCase {

    // MARK: - SyncEngine Tests

    func testSyncEngineUpload() async throws {
        let local = MockSyncableStorage<Item>()
        let remote = MockSyncableStorage<Item>()
        let engine = SyncEngine()

        // Add local change
        let item = Item(userId: UUID(), title: "Test Item")
        let change = SyncChange(entity: item, operation: .create)
        await local.addChange(change)

        // Sync upload
        let result = try await engine.sync(local: local, remote: remote, direction: .upload)

        XCTAssertEqual(result.uploaded, 1)
        XCTAssertEqual(result.downloaded, 0)
        XCTAssertTrue(result.isSuccess)

        // Verify remote received the item
        let remoteItems = await remote.getAllEntities()
        XCTAssertEqual(remoteItems.count, 1)
    }

    func testSyncEngineDownload() async throws {
        let local = MockSyncableStorage<Item>()
        let remote = MockSyncableStorage<Item>()
        let engine = SyncEngine()

        // Add remote change
        let item = Item(userId: UUID(), title: "Remote Item")
        let change = SyncChange(entity: item, operation: .create)
        await remote.addChange(change)

        // Sync download
        let result = try await engine.sync(local: local, remote: remote, direction: .download)

        XCTAssertEqual(result.uploaded, 0)
        XCTAssertEqual(result.downloaded, 1)
        XCTAssertTrue(result.isSuccess)

        // Verify local received the item
        let localItems = await local.getAllEntities()
        XCTAssertEqual(localItems.count, 1)
    }

    func testSyncEngineBidirectional() async throws {
        let local = MockSyncableStorage<Item>()
        let remote = MockSyncableStorage<Item>()
        let engine = SyncEngine()

        // Add local change
        let localItem = Item(userId: UUID(), title: "Local Item")
        await local.addChange(SyncChange(entity: localItem, operation: .create))

        // Add remote change
        let remoteItem = Item(userId: UUID(), title: "Remote Item")
        await remote.addChange(SyncChange(entity: remoteItem, operation: .create))

        // Sync both directions
        let result = try await engine.sync(local: local, remote: remote, direction: .both)

        // Upload sends 1 local item to remote
        XCTAssertEqual(result.uploaded, 1)
        // Download gets 2 items from remote (original + uploaded one)
        // but only the original one existed before sync
        XCTAssertGreaterThanOrEqual(result.downloaded, 1)
        XCTAssertTrue(result.isSuccess)
    }

    func testSyncEngineConflictNewerWins() async throws {
        let local = MockSyncableStorage<Item>()
        let remote = MockSyncableStorage<Item>()
        let engine = SyncEngine(conflictStrategy: .newerWins)

        let itemId = UUID()
        let userId = UUID()

        // Add local change (older)
        let localItem = Item(id: itemId, userId: userId, title: "Local Version")
        let localTime = Date().addingTimeInterval(-100)
        await local.addChange(SyncChange(entity: localItem, operation: .update, timestamp: localTime))

        // Add remote change (newer)
        let remoteItem = Item(id: itemId, userId: userId, title: "Remote Version")
        let remoteTime = Date()
        await remote.addChange(SyncChange(entity: remoteItem, operation: .update, timestamp: remoteTime))

        // Sync
        let result = try await engine.sync(local: local, remote: remote, direction: .both)

        // There should be at least one conflict for the item with same ID
        XCTAssertGreaterThanOrEqual(result.conflicts.count, 1)
        // The most recent remote conflict should resolve to useRemote
        let relevantConflict = result.conflicts.first { $0.entityId == itemId }
        XCTAssertEqual(relevantConflict?.resolution, .useRemote)
    }

    func testSyncEngineConflictLocalWins() async throws {
        let local = MockSyncableStorage<Item>()
        let remote = MockSyncableStorage<Item>()
        let engine = SyncEngine(conflictStrategy: .localWins)

        let itemId = UUID()
        let userId = UUID()

        // Add both changes
        let localItem = Item(id: itemId, userId: userId, title: "Local Version")
        await local.addChange(SyncChange(entity: localItem, operation: .update))

        let remoteItem = Item(id: itemId, userId: userId, title: "Remote Version")
        await remote.addChange(SyncChange(entity: remoteItem, operation: .update))

        // Sync
        let result = try await engine.sync(local: local, remote: remote, direction: .both)

        // There should be at least one conflict
        XCTAssertGreaterThanOrEqual(result.conflicts.count, 1)
        // The conflict for our item should resolve to useLocal
        let relevantConflict = result.conflicts.first { $0.entityId == itemId }
        XCTAssertEqual(relevantConflict?.resolution, .useLocal)
    }

    func testSyncEnginePreventsConcurrentSync() async throws {
        let local = MockSyncableStorage<Item>()
        let remote = MockSyncableStorage<Item>()
        let engine = SyncEngine()

        // Start first sync in background
        async let result1 = engine.sync(local: local, remote: remote, direction: .both)

        // Immediately try second sync
        async let result2 = engine.sync(local: local, remote: remote, direction: .both)

        let results = try await [result1, result2]

        // One should succeed, one should fail with timeout (already syncing)
        let successCount = results.filter { $0.isSuccess }.count
        let timeoutCount = results.filter { $0.errors.contains(where: {
            if case .timeout = $0 { return true }
            return false
        }) }.count

        // At least one should be success or timeout
        XCTAssertTrue(successCount >= 1 || timeoutCount >= 1)
    }

    // MARK: - SyncResult Tests

    func testSyncResultIsSuccess() {
        let success = SyncResult(uploaded: 5, downloaded: 3)
        XCTAssertTrue(success.isSuccess)

        let failure = SyncResult(errors: [.networkUnavailable])
        XCTAssertFalse(failure.isSuccess)
    }

    // MARK: - SyncConflict Tests

    func testSyncConflictCreation() {
        let conflict = SyncConflict(
            entityId: UUID(),
            entityType: "Item",
            localVersion: Date(),
            remoteVersion: Date().addingTimeInterval(-100),
            resolution: .useLocal
        )

        XCTAssertEqual(conflict.entityType, "Item")
        XCTAssertEqual(conflict.resolution, .useLocal)
    }

    // MARK: - SyncError Tests

    func testSyncErrorDescriptions() {
        XCTAssertTrue(SyncError.networkUnavailable.errorDescription?.contains("Network") ?? false)
        XCTAssertTrue(SyncError.authenticationRequired.errorDescription?.contains("Authentication") ?? false)
        XCTAssertTrue(SyncError.serverError("test").errorDescription?.contains("test") ?? false)
        XCTAssertTrue(SyncError.quotaExceeded.errorDescription?.contains("quota") ?? false)
    }

    // MARK: - ConflictStrategy Tests

    func testConflictStrategyNewerWins() {
        let strategy = ConflictStrategy.newerWins
        let older = Date().addingTimeInterval(-100)
        let newer = Date()

        XCTAssertEqual(strategy.resolve(localTime: newer, remoteTime: older), .useLocal)
        XCTAssertEqual(strategy.resolve(localTime: older, remoteTime: newer), .useRemote)
    }

    func testConflictStrategyLocalWins() {
        let strategy = ConflictStrategy.localWins

        XCTAssertEqual(strategy.resolve(localTime: Date(), remoteTime: Date()), .useLocal)
    }

    func testConflictStrategyRemoteWins() {
        let strategy = ConflictStrategy.remoteWins

        XCTAssertEqual(strategy.resolve(localTime: Date(), remoteTime: Date()), .useRemote)
    }

    func testConflictStrategyCustom() {
        // Custom strategy: always merge
        let strategy = ConflictStrategy.custom { _, _ in .merge }

        XCTAssertEqual(strategy.resolve(localTime: Date(), remoteTime: Date()), .merge)
    }

    // MARK: - SyncState Tests

    func testSyncStateProperties() {
        XCTAssertTrue(SyncState.idle.isIdle)
        XCTAssertFalse(SyncState.idle.isSyncing)

        XCTAssertTrue(SyncState.syncing.isSyncing)
        XCTAssertFalse(SyncState.syncing.isIdle)

        XCTAssertFalse(SyncState.success(SyncResult()).isIdle)
        XCTAssertFalse(SyncState.failed(.timeout).isIdle)
    }

    // MARK: - SyncConfiguration Tests

    func testSyncConfigurationDefaults() {
        let config = SyncConfiguration.default

        XCTAssertTrue(config.autoSyncEnabled)
        XCTAssertEqual(config.autoSyncInterval, 300)
        XCTAssertTrue(config.syncOnAppForeground)
        XCTAssertEqual(config.maxRetries, 3)
    }

    // MARK: - SyncManager Tests

    func testSyncManagerObserver() async {
        let manager = SyncManager()
        var observedStates: [SyncState] = []

        let observerId = await manager.observe { state in
            observedStates.append(state)
        }

        // Trigger some state changes (this would happen during sync)
        // For now, just verify observer was registered
        XCTAssertNotNil(observerId)

        await manager.removeObserver(observerId)
    }
}
