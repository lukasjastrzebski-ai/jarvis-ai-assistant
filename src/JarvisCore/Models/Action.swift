import Foundation

/// Represents an action or activity logged in the system
public struct Action: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var userId: UUID
    public var actionType: ActionType
    public var targetType: TargetType
    public var targetId: UUID?
    public var description: String
    public var metadata: [String: String]
    public var timestamp: Date
    public var deviceId: String?
    public var sessionId: UUID?

    public init(
        id: UUID = UUID(),
        userId: UUID,
        actionType: ActionType,
        targetType: TargetType,
        targetId: UUID? = nil,
        description: String,
        metadata: [String: String] = [:],
        timestamp: Date = Date(),
        deviceId: String? = nil,
        sessionId: UUID? = nil
    ) {
        self.id = id
        self.userId = userId
        self.actionType = actionType
        self.targetType = targetType
        self.targetId = targetId
        self.description = description
        self.metadata = metadata
        self.timestamp = timestamp
        self.deviceId = deviceId
        self.sessionId = sessionId
    }
}

/// Type of action performed
public enum ActionType: String, Codable, CaseIterable, Sendable {
    // CRUD operations
    case create
    case read
    case update
    case delete

    // Item-specific actions
    case complete
    case uncomplete
    case archive
    case restore
    case schedule
    case reschedule
    case prioritize
    case tag
    case untag

    // Navigation/UI actions
    case view
    case search
    case filter

    // System actions
    case sync
    case login
    case logout
    case settingsChange
}

/// Type of entity the action targets
public enum TargetType: String, Codable, CaseIterable, Sendable {
    case item
    case memory
    case user
    case calendar
    case settings
    case system
}

/// Query parameters for filtering actions
public struct ActionQuery: Sendable {
    public var userId: UUID?
    public var actionTypes: [ActionType]?
    public var targetTypes: [TargetType]?
    public var targetId: UUID?
    public var startDate: Date?
    public var endDate: Date?
    public var limit: Int?
    public var offset: Int?

    public init(
        userId: UUID? = nil,
        actionTypes: [ActionType]? = nil,
        targetTypes: [TargetType]? = nil,
        targetId: UUID? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.userId = userId
        self.actionTypes = actionTypes
        self.targetTypes = targetTypes
        self.targetId = targetId
        self.startDate = startDate
        self.endDate = endDate
        self.limit = limit
        self.offset = offset
    }
}
