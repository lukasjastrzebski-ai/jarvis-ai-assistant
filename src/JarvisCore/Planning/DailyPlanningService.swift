import Foundation

/// A planned outcome for the day
public struct PlannedOutcome: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var description: String?
    public var urgency: UrgencyLevel
    public var importance: ImportanceLevel
    public var estimatedMinutes: Int
    public var timeBlock: TimeBlock?
    public var sourceItemId: UUID?
    public var sourceType: SourceType
    public var isCompleted: Bool
    public var completedAt: Date?

    public enum UrgencyLevel: Int, Codable, Sendable, CaseIterable, Comparable {
        case low = 1
        case medium = 2
        case high = 3
        case critical = 4

        public static func < (lhs: UrgencyLevel, rhs: UrgencyLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public enum ImportanceLevel: Int, Codable, Sendable, CaseIterable, Comparable {
        case low = 1
        case medium = 2
        case high = 3
        case critical = 4

        public static func < (lhs: ImportanceLevel, rhs: ImportanceLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public enum SourceType: String, Codable, Sendable {
        case task
        case calendar
        case email
        case manual
    }

    public init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        urgency: UrgencyLevel = .medium,
        importance: ImportanceLevel = .medium,
        estimatedMinutes: Int = 30,
        timeBlock: TimeBlock? = nil,
        sourceItemId: UUID? = nil,
        sourceType: SourceType = .manual,
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.urgency = urgency
        self.importance = importance
        self.estimatedMinutes = estimatedMinutes
        self.timeBlock = timeBlock
        self.sourceItemId = sourceItemId
        self.sourceType = sourceType
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }

    /// Priority score combining urgency and importance (Eisenhower matrix style)
    public var priorityScore: Int {
        urgency.rawValue * 2 + importance.rawValue
    }
}

/// Time block for scheduling
public struct TimeBlock: Codable, Equatable, Sendable {
    public let start: Date
    public let end: Date

    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }

    public var duration: TimeInterval {
        end.timeIntervalSince(start)
    }

    public var durationMinutes: Int {
        Int(duration / 60)
    }
}

/// Daily plan containing all planned outcomes
public struct DailyPlan: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let date: Date
    public var outcomes: [PlannedOutcome]
    public var calendarEvents: [CalendarEventSummary]
    public var totalPlannedMinutes: Int
    public var availableMinutes: Int
    public var isOverloaded: Bool
    public var warnings: [PlanWarning]
    public var status: PlanStatus
    public var createdAt: Date
    public var modifiedAt: Date

    public enum PlanStatus: String, Codable, Sendable {
        case draft
        case accepted
        case inProgress
        case completed
        case abandoned
    }

    public init(
        id: UUID = UUID(),
        date: Date,
        outcomes: [PlannedOutcome] = [],
        calendarEvents: [CalendarEventSummary] = [],
        totalPlannedMinutes: Int = 0,
        availableMinutes: Int = 480, // 8 hour workday default
        isOverloaded: Bool = false,
        warnings: [PlanWarning] = [],
        status: PlanStatus = .draft,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.outcomes = outcomes
        self.calendarEvents = calendarEvents
        self.totalPlannedMinutes = totalPlannedMinutes
        self.availableMinutes = availableMinutes
        self.isOverloaded = isOverloaded
        self.warnings = warnings
        self.status = status
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    /// Progress percentage (0-100)
    public var progressPercentage: Int {
        guard !outcomes.isEmpty else { return 0 }
        let completed = outcomes.filter { $0.isCompleted }.count
        return Int((Double(completed) / Double(outcomes.count)) * 100)
    }
}

/// Summary of a calendar event for plan display
public struct CalendarEventSummary: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let startTime: Date
    public let endTime: Date
    public let isAllDay: Bool

    public init(id: String, title: String, startTime: Date, endTime: Date, isAllDay: Bool = false) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.isAllDay = isAllDay
    }

    public var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }
}

/// Warning about plan issues
public struct PlanWarning: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let type: WarningType
    public let message: String
    public let suggestion: String?

    public enum WarningType: String, Codable, Sendable {
        case overloaded
        case noBreaks
        case conflictingPriorities
        case unrealisticEstimate
        case missingDeadline
    }

    public init(id: UUID = UUID(), type: WarningType, message: String, suggestion: String? = nil) {
        self.id = id
        self.type = type
        self.message = message
        self.suggestion = suggestion
    }
}

/// Service for daily planning operations
public actor DailyPlanningService {
    private var plans: [Date: DailyPlan] = [:] // Keyed by date (start of day)
    private let workdayStartHour: Int
    private let workdayEndHour: Int

    public init(workdayStartHour: Int = 9, workdayEndHour: Int = 17) {
        self.workdayStartHour = workdayStartHour
        self.workdayEndHour = workdayEndHour
    }

    // MARK: - Plan Generation

    /// Generate a daily plan from items and calendar events
    public func generatePlan(
        for date: Date,
        items: [Item],
        calendarEvents: [CalendarEvent]
    ) async -> DailyPlan {
        let calendar = Foundation.Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // Convert calendar events to summaries
        let eventSummaries = calendarEvents.map { event in
            CalendarEventSummary(
                id: event.id,
                title: event.title,
                startTime: event.startDate,
                endTime: event.endDate,
                isAllDay: event.isAllDay
            )
        }

        // Calculate time blocked by events
        let eventMinutes = eventSummaries
            .filter { !$0.isAllDay }
            .reduce(0) { $0 + $1.durationMinutes }

        // Calculate available working minutes
        let workdayMinutes = (workdayEndHour - workdayStartHour) * 60
        let availableMinutes = max(0, workdayMinutes - eventMinutes)

        // Filter and rank items for today
        let todayItems = items.filter { item in
            // Include items due today or overdue
            if let dueDate = item.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: date) || dueDate < date
            }
            // Include items scheduled for today
            if item.status == .today {
                return true
            }
            // Include high priority items
            return item.priority == .high || item.priority == .urgent
        }

        // Convert items to planned outcomes and rank
        var outcomes = todayItems.map { item -> PlannedOutcome in
            PlannedOutcome(
                title: item.title,
                description: item.content,
                urgency: mapPriority(item.priority),
                importance: mapPriorityToImportance(item.priority), // Using priority as proxy for importance
                estimatedMinutes: 30, // Default estimate
                sourceItemId: item.id,
                sourceType: .task
            )
        }

        // Sort by priority score (highest first)
        outcomes.sort { $0.priorityScore > $1.priorityScore }

        // Limit to top 5 outcomes
        outcomes = Array(outcomes.prefix(5))

        // Assign time blocks to outcomes
        outcomes = assignTimeBlocks(to: outcomes, on: date, avoiding: eventSummaries)

        // Calculate total planned time
        let totalPlannedMinutes = outcomes.reduce(0) { $0 + $1.estimatedMinutes }

        // Check for overload
        let isOverloaded = totalPlannedMinutes > availableMinutes

        // Generate warnings
        var warnings: [PlanWarning] = []

        if isOverloaded {
            let overageMinutes = totalPlannedMinutes - availableMinutes
            warnings.append(PlanWarning(
                type: .overloaded,
                message: "Plan exceeds available time by \(overageMinutes) minutes",
                suggestion: "Consider moving \(outcomes.last?.title ?? "a task") to tomorrow"
            ))
        }

        // Check for no breaks
        if totalPlannedMinutes > 240 && outcomes.count >= 4 {
            warnings.append(PlanWarning(
                type: .noBreaks,
                message: "Long planning day without scheduled breaks",
                suggestion: "Add a 15-minute break between tasks"
            ))
        }

        let plan = DailyPlan(
            date: startOfDay,
            outcomes: outcomes,
            calendarEvents: eventSummaries,
            totalPlannedMinutes: totalPlannedMinutes,
            availableMinutes: availableMinutes,
            isOverloaded: isOverloaded,
            warnings: warnings
        )

        plans[startOfDay] = plan
        return plan
    }

    /// Generate today's plan
    public func generateTodaysPlan(items: [Item], calendarEvents: [CalendarEvent]) async -> DailyPlan {
        return await generatePlan(for: Date(), items: items, calendarEvents: calendarEvents)
    }

    // MARK: - Plan Retrieval

    /// Get plan for a specific date
    public func getPlan(for date: Date) -> DailyPlan? {
        let calendar = Foundation.Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return plans[startOfDay]
    }

    /// Get today's plan
    public func getTodaysPlan() -> DailyPlan? {
        return getPlan(for: Date())
    }

    // MARK: - Plan Modification

    /// Accept a plan
    public func acceptPlan(planId: UUID) async throws {
        guard let key = findPlanKey(planId: planId) else {
            throw PlanningError.planNotFound
        }

        var plan = plans[key]!
        plan.status = .accepted
        plan.modifiedAt = Date()
        plans[key] = plan
    }

    /// Update an outcome in the plan
    public func updateOutcome(_ outcome: PlannedOutcome, in planId: UUID) async throws {
        guard let key = findPlanKey(planId: planId) else {
            throw PlanningError.planNotFound
        }

        var plan = plans[key]!
        guard let index = plan.outcomes.firstIndex(where: { $0.id == outcome.id }) else {
            throw PlanningError.outcomeNotFound
        }

        plan.outcomes[index] = outcome
        plan.modifiedAt = Date()

        // Recalculate totals
        plan.totalPlannedMinutes = plan.outcomes.reduce(0) { $0 + $1.estimatedMinutes }
        plan.isOverloaded = plan.totalPlannedMinutes > plan.availableMinutes

        plans[key] = plan
    }

    /// Mark an outcome as complete
    public func completeOutcome(outcomeId: UUID, in planId: UUID) async throws {
        guard let key = findPlanKey(planId: planId) else {
            throw PlanningError.planNotFound
        }

        var plan = plans[key]!
        guard let index = plan.outcomes.firstIndex(where: { $0.id == outcomeId }) else {
            throw PlanningError.outcomeNotFound
        }

        plan.outcomes[index].isCompleted = true
        plan.outcomes[index].completedAt = Date()
        plan.modifiedAt = Date()

        // Check if all outcomes completed
        if plan.outcomes.allSatisfy({ $0.isCompleted }) {
            plan.status = .completed
        } else if plan.status == .accepted {
            plan.status = .inProgress
        }

        plans[key] = plan
    }

    /// Add an outcome to the plan
    public func addOutcome(_ outcome: PlannedOutcome, to planId: UUID) async throws {
        guard let key = findPlanKey(planId: planId) else {
            throw PlanningError.planNotFound
        }

        var plan = plans[key]!
        plan.outcomes.append(outcome)
        plan.totalPlannedMinutes += outcome.estimatedMinutes
        plan.isOverloaded = plan.totalPlannedMinutes > plan.availableMinutes
        plan.modifiedAt = Date()

        // Add warning if now overloaded
        if plan.isOverloaded && !plan.warnings.contains(where: { $0.type == .overloaded }) {
            plan.warnings.append(PlanWarning(
                type: .overloaded,
                message: "Plan now exceeds available time",
                suggestion: "Consider removing or rescheduling an item"
            ))
        }

        plans[key] = plan
    }

    /// Remove an outcome from the plan
    public func removeOutcome(outcomeId: UUID, from planId: UUID) async throws {
        guard let key = findPlanKey(planId: planId) else {
            throw PlanningError.planNotFound
        }

        var plan = plans[key]!
        guard let index = plan.outcomes.firstIndex(where: { $0.id == outcomeId }) else {
            throw PlanningError.outcomeNotFound
        }

        let removed = plan.outcomes.remove(at: index)
        plan.totalPlannedMinutes -= removed.estimatedMinutes
        plan.isOverloaded = plan.totalPlannedMinutes > plan.availableMinutes
        plan.modifiedAt = Date()

        // Remove overload warning if no longer overloaded
        if !plan.isOverloaded {
            plan.warnings.removeAll { $0.type == .overloaded }
        }

        plans[key] = plan
    }

    /// Reorder outcomes
    public func reorderOutcomes(from sourceIndex: Int, to destinationIndex: Int, in planId: UUID) async throws {
        guard let key = findPlanKey(planId: planId) else {
            throw PlanningError.planNotFound
        }

        var plan = plans[key]!
        guard sourceIndex >= 0, sourceIndex < plan.outcomes.count,
              destinationIndex >= 0, destinationIndex <= plan.outcomes.count else {
            throw PlanningError.invalidIndex
        }

        let outcome = plan.outcomes.remove(at: sourceIndex)
        let adjustedDestination = destinationIndex > sourceIndex ? destinationIndex - 1 : destinationIndex
        plan.outcomes.insert(outcome, at: adjustedDestination)
        plan.modifiedAt = Date()

        plans[key] = plan
    }

    // MARK: - Time Block Suggestions

    /// Find suggested time blocks for an outcome
    public func suggestTimeBlocks(
        for outcome: PlannedOutcome,
        on date: Date,
        avoiding events: [CalendarEventSummary]
    ) -> [TimeBlock] {
        let calendar = Foundation.Calendar.current

        guard let workdayStart = calendar.date(
            bySettingHour: workdayStartHour, minute: 0, second: 0, of: date
        ),
        let workdayEnd = calendar.date(
            bySettingHour: workdayEndHour, minute: 0, second: 0, of: date
        ) else {
            return []
        }

        let durationSeconds = TimeInterval(outcome.estimatedMinutes * 60)
        var suggestions: [TimeBlock] = []
        var currentStart = workdayStart

        // Sort events by start time
        let sortedEvents = events.filter { !$0.isAllDay }.sorted { $0.startTime < $1.startTime }

        for event in sortedEvents {
            // Check gap before event
            let gapDuration = event.startTime.timeIntervalSince(currentStart)
            if gapDuration >= durationSeconds {
                let blockEnd = currentStart.addingTimeInterval(durationSeconds)
                suggestions.append(TimeBlock(start: currentStart, end: blockEnd))
            }
            currentStart = max(currentStart, event.endTime)
        }

        // Check remaining time after last event
        let remainingDuration = workdayEnd.timeIntervalSince(currentStart)
        if remainingDuration >= durationSeconds {
            let blockEnd = currentStart.addingTimeInterval(durationSeconds)
            suggestions.append(TimeBlock(start: currentStart, end: blockEnd))
        }

        return suggestions
    }

    // MARK: - Errors

    public enum PlanningError: Error, LocalizedError, Equatable {
        case planNotFound
        case outcomeNotFound
        case invalidIndex
        case cannotModifyCompletedPlan

        public var errorDescription: String? {
            switch self {
            case .planNotFound:
                return "Plan not found"
            case .outcomeNotFound:
                return "Outcome not found in plan"
            case .invalidIndex:
                return "Invalid index for reordering"
            case .cannotModifyCompletedPlan:
                return "Cannot modify a completed plan"
            }
        }
    }

    // MARK: - Private Helpers

    private func findPlanKey(planId: UUID) -> Date? {
        return plans.first(where: { $0.value.id == planId })?.key
    }

    private func mapPriority(_ priority: Priority) -> PlannedOutcome.UrgencyLevel {
        switch priority {
        case .urgent:
            return .critical
        case .high:
            return .high
        case .medium:
            return .medium
        case .low:
            return .low
        }
    }

    private func mapPriorityToImportance(_ priority: Priority) -> PlannedOutcome.ImportanceLevel {
        switch priority {
        case .urgent:
            return .critical
        case .high:
            return .high
        case .medium:
            return .medium
        case .low:
            return .low
        }
    }

    private func assignTimeBlocks(
        to outcomes: [PlannedOutcome],
        on date: Date,
        avoiding events: [CalendarEventSummary]
    ) -> [PlannedOutcome] {
        var result = outcomes
        var assignedBlocks: [TimeBlock] = []

        for (index, outcome) in result.enumerated() {
            let suggestions = suggestTimeBlocks(for: outcome, on: date, avoiding: events)

            // Find first suggestion that doesn't overlap with already assigned blocks
            for suggestion in suggestions {
                let overlaps = assignedBlocks.contains { block in
                    suggestion.start < block.end && block.start < suggestion.end
                }

                if !overlaps {
                    result[index].timeBlock = suggestion
                    assignedBlocks.append(suggestion)
                    break
                }
            }
        }

        return result
    }
}
