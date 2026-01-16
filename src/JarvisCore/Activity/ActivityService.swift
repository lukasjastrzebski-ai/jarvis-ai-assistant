import Foundation

/// Service for logging and querying user activity
public actor ActivityService {
    private let storage: any ActionStorageProtocol

    public init(storage: any ActionStorageProtocol) {
        self.storage = storage
    }

    // MARK: - Logging Actions

    /// Log an action
    public func log(
        userId: UUID,
        actionType: ActionType,
        targetType: TargetType,
        targetId: UUID? = nil,
        description: String,
        metadata: [String: String] = [:],
        deviceId: String? = nil,
        sessionId: UUID? = nil
    ) async throws -> Action {
        let action = Action(
            userId: userId,
            actionType: actionType,
            targetType: targetType,
            targetId: targetId,
            description: description,
            metadata: metadata,
            deviceId: deviceId,
            sessionId: sessionId
        )

        try await storage.save(action)
        return action
    }

    /// Log a create action
    public func logCreate(
        userId: UUID,
        targetType: TargetType,
        targetId: UUID,
        description: String,
        metadata: [String: String] = [:]
    ) async throws -> Action {
        return try await log(
            userId: userId,
            actionType: .create,
            targetType: targetType,
            targetId: targetId,
            description: description,
            metadata: metadata
        )
    }

    /// Log an update action
    public func logUpdate(
        userId: UUID,
        targetType: TargetType,
        targetId: UUID,
        description: String,
        metadata: [String: String] = [:]
    ) async throws -> Action {
        return try await log(
            userId: userId,
            actionType: .update,
            targetType: targetType,
            targetId: targetId,
            description: description,
            metadata: metadata
        )
    }

    /// Log a delete action
    public func logDelete(
        userId: UUID,
        targetType: TargetType,
        targetId: UUID,
        description: String
    ) async throws -> Action {
        return try await log(
            userId: userId,
            actionType: .delete,
            targetType: targetType,
            targetId: targetId,
            description: description
        )
    }

    /// Log item completion
    public func logItemComplete(
        userId: UUID,
        itemId: UUID,
        itemTitle: String
    ) async throws -> Action {
        return try await log(
            userId: userId,
            actionType: .complete,
            targetType: .item,
            targetId: itemId,
            description: "Completed: \(itemTitle)",
            metadata: ["title": itemTitle]
        )
    }

    /// Log a view action
    public func logView(
        userId: UUID,
        targetType: TargetType,
        targetId: UUID? = nil,
        description: String
    ) async throws -> Action {
        return try await log(
            userId: userId,
            actionType: .view,
            targetType: targetType,
            targetId: targetId,
            description: description
        )
    }

    /// Log a search action
    public func logSearch(
        userId: UUID,
        query: String,
        resultCount: Int
    ) async throws -> Action {
        return try await log(
            userId: userId,
            actionType: .search,
            targetType: .system,
            description: "Search: \(query)",
            metadata: ["query": query, "resultCount": String(resultCount)]
        )
    }

    // MARK: - Querying Actions

    /// Get recent actions for a user
    public func getRecentActions(
        userId: UUID,
        limit: Int = 50
    ) async throws -> [Action] {
        return try await storage.fetchRecent(userId: userId, limit: limit)
    }

    /// Get actions by query
    public func getActions(query: ActionQuery) async throws -> [Action] {
        return try await storage.fetch(query: query)
    }

    /// Get actions for a specific target
    public func getActions(
        forTarget targetId: UUID,
        targetType: TargetType,
        userId: UUID
    ) async throws -> [Action] {
        let query = ActionQuery(
            userId: userId,
            targetTypes: [targetType],
            targetId: targetId
        )
        return try await storage.fetch(query: query)
    }

    /// Get actions by type
    public func getActions(
        ofType actionType: ActionType,
        userId: UUID,
        limit: Int = 50
    ) async throws -> [Action] {
        let query = ActionQuery(
            userId: userId,
            actionTypes: [actionType],
            limit: limit
        )
        return try await storage.fetch(query: query)
    }

    /// Get actions in date range
    public func getActions(
        userId: UUID,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [Action] {
        let query = ActionQuery(
            userId: userId,
            startDate: startDate,
            endDate: endDate
        )
        return try await storage.fetch(query: query)
    }

    // MARK: - Analytics

    /// Get action counts by type for a user
    public func getActionCounts(userId: UUID) async throws -> [ActionType: Int] {
        let actions = try await storage.fetchAll()
        let userActions = actions.filter { $0.userId == userId }

        var counts: [ActionType: Int] = [:]
        for action in userActions {
            counts[action.actionType, default: 0] += 1
        }
        return counts
    }

    /// Get activity summary for a date range
    public func getActivitySummary(
        userId: UUID,
        from startDate: Date,
        to endDate: Date
    ) async throws -> ActivitySummary {
        let actions = try await getActions(userId: userId, from: startDate, to: endDate)

        let creates = actions.filter { $0.actionType == .create }.count
        let updates = actions.filter { $0.actionType == .update }.count
        let completes = actions.filter { $0.actionType == .complete }.count
        let views = actions.filter { $0.actionType == .view }.count
        let searches = actions.filter { $0.actionType == .search }.count

        // Find most active hour
        var hourCounts: [Int: Int] = [:]
        let cal = Foundation.Calendar.current
        for action in actions {
            let hour = cal.component(.hour, from: action.timestamp)
            hourCounts[hour, default: 0] += 1
        }
        let mostActiveHour = hourCounts.max(by: { $0.value < $1.value })?.key

        return ActivitySummary(
            totalActions: actions.count,
            creates: creates,
            updates: updates,
            completes: completes,
            views: views,
            searches: searches,
            mostActiveHour: mostActiveHour,
            startDate: startDate,
            endDate: endDate
        )
    }
}

/// Summary of activity for analytics
public struct ActivitySummary: Sendable {
    public let totalActions: Int
    public let creates: Int
    public let updates: Int
    public let completes: Int
    public let views: Int
    public let searches: Int
    public let mostActiveHour: Int?
    public let startDate: Date
    public let endDate: Date

    public init(
        totalActions: Int,
        creates: Int,
        updates: Int,
        completes: Int,
        views: Int,
        searches: Int,
        mostActiveHour: Int?,
        startDate: Date,
        endDate: Date
    ) {
        self.totalActions = totalActions
        self.creates = creates
        self.updates = updates
        self.completes = completes
        self.views = views
        self.searches = searches
        self.mostActiveHour = mostActiveHour
        self.startDate = startDate
        self.endDate = endDate
    }
}
