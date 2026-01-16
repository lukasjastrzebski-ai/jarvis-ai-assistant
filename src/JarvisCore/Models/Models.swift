/// JarvisCore Models
///
/// This file re-exports all model types for convenient importing.
/// Usage: import JarvisCore

import Foundation

// All models are defined in their respective files:
// - User.swift: User and UserPreferences
// - Item.swift: Item, ItemType, ItemStatus, Priority, SourceType
// - Memory.swift: Memory, MemoryType, MemoryCategory, MemorySource, MemorySearchResult
// - Action.swift: Action, ActionType, TargetType, ActionQuery

/// Sync status for tracking synchronization state
public enum SyncStatus: String, Codable, Sendable {
    case synced      // In sync with cloud
    case pending     // Local changes pending upload
    case conflict    // Conflict detected
    case error       // Sync error occurred
}

/// Protocol for entities that can be synced
public protocol Syncable: Identifiable, Codable where ID == UUID {
    var id: UUID { get }
    var createdAt: Date { get }
    var updatedAt: Date { get set }
}

// Conformances
extension User: Syncable {}
extension Item: Syncable {}
extension Memory: Syncable {}
