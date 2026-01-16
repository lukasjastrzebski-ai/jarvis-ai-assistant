import Foundation

/// Represents an item in the Jarvis inbox/task system
public struct Item: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var userId: UUID
    public var title: String
    public var content: String?
    public var itemType: ItemType
    public var status: ItemStatus
    public var priority: Priority
    public var dueDate: Date?
    public var completedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date
    public var tags: [String]
    public var parentId: UUID?
    public var sourceId: String?
    public var sourceType: SourceType?

    public init(
        id: UUID = UUID(),
        userId: UUID,
        title: String,
        content: String? = nil,
        itemType: ItemType = .task,
        status: ItemStatus = .inbox,
        priority: Priority = .medium,
        dueDate: Date? = nil,
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        tags: [String] = [],
        parentId: UUID? = nil,
        sourceId: String? = nil,
        sourceType: SourceType? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.content = content
        self.itemType = itemType
        self.status = status
        self.priority = priority
        self.dueDate = dueDate
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
        self.parentId = parentId
        self.sourceId = sourceId
        self.sourceType = sourceType
    }
}

/// Type of item
public enum ItemType: String, Codable, CaseIterable, Sendable {
    case task
    case note
    case event
    case reminder
    case reference
}

/// Status of an item in the workflow
public enum ItemStatus: String, Codable, CaseIterable, Sendable {
    case inbox       // Newly captured, needs processing
    case today       // Scheduled for today
    case scheduled   // Scheduled for a future date
    case someday     // No specific date, maybe later
    case completed   // Done
    case archived    // Archived/hidden
}

/// Priority level
public enum Priority: Int, Codable, CaseIterable, Sendable, Comparable {
    case low = 0
    case medium = 1
    case high = 2
    case urgent = 3

    public static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Source of the item (for items captured from external sources)
public enum SourceType: String, Codable, Sendable {
    case manual      // User created
    case email       // From email
    case calendar    // From calendar
    case siri        // From Siri
    case shortcut    // From Shortcuts
    case api         // From API
}
