import SwiftUI
import JarvisCore

/// View model for the Activity Log
@MainActor
public class ActivityLogViewModel: ObservableObject {
    // MARK: - Published State

    @Published public var actions: [Action] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var filterType: ActivityFilter = .all
    @Published public var dateRange: ActivityDateRange = .today
    @Published public var selectedAction: Action?
    @Published public var showActionDetail: Bool = false

    // MARK: - Dependencies

    private let activityService: ActivityService
    private let userId: UUID

    // MARK: - Computed Properties

    /// Filtered actions based on current filters
    public var filteredActions: [Action] {
        var result = actions

        // Filter by type
        switch filterType {
        case .all:
            break
        case .creates:
            result = result.filter { $0.actionType == .create }
        case .updates:
            result = result.filter { $0.actionType == .update }
        case .deletes:
            result = result.filter { $0.actionType == .delete }
        case .completes:
            result = result.filter { $0.actionType == .complete }
        case .views:
            result = result.filter { $0.actionType == .view }
        case .searches:
            result = result.filter { $0.actionType == .search }
        }

        return result
    }

    /// Actions grouped by date
    public var groupedActions: [(date: Date, actions: [Action])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredActions) { action in
            calendar.startOfDay(for: action.timestamp)
        }
        return grouped.map { (date: $0.key, actions: $0.value) }
            .sorted { $0.date > $1.date }
    }

    /// Summary statistics
    public var summary: ActivitySummary? {
        guard !actions.isEmpty else { return nil }
        let startDate = actions.map { $0.timestamp }.min() ?? Date()
        let endDate = actions.map { $0.timestamp }.max() ?? Date()

        return ActivitySummary(
            totalActions: actions.count,
            creates: actions.filter { $0.actionType == .create }.count,
            updates: actions.filter { $0.actionType == .update }.count,
            completes: actions.filter { $0.actionType == .complete }.count,
            views: actions.filter { $0.actionType == .view }.count,
            searches: actions.filter { $0.actionType == .search }.count,
            mostActiveHour: findMostActiveHour(),
            startDate: startDate,
            endDate: endDate
        )
    }

    // MARK: - Initialization

    public init(activityService: ActivityService, userId: UUID) {
        self.activityService = activityService
        self.userId = userId
    }

    // MARK: - Actions

    /// Load actions for the current date range
    public func loadActions() async {
        isLoading = true
        errorMessage = nil

        do {
            let (startDate, endDate) = dateRangeDates()
            actions = try await activityService.getActions(
                userId: userId,
                from: startDate,
                to: endDate
            )
        } catch {
            errorMessage = "Failed to load activity: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Refresh actions
    public func refresh() async {
        await loadActions()
    }

    /// Select an action for detail view
    public func selectAction(_ action: Action) {
        selectedAction = action
        showActionDetail = true
    }

    /// Clear selection
    public func clearSelection() {
        selectedAction = nil
        showActionDetail = false
    }

    /// Export actions as JSON
    public func exportActions() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(filteredActions)
    }

    // MARK: - Private Helpers

    private func dateRangeDates() -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let endDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!

        let startDate: Date
        switch dateRange {
        case .today:
            startDate = calendar.startOfDay(for: now)
        case .thisWeek:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        case .thisMonth:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)!
        case .allTime:
            startDate = Date.distantPast
        }

        return (startDate, endDate)
    }

    private func findMostActiveHour() -> Int? {
        guard !actions.isEmpty else { return nil }
        let calendar = Calendar.current
        var hourCounts: [Int: Int] = [:]
        for action in actions {
            let hour = calendar.component(.hour, from: action.timestamp)
            hourCounts[hour, default: 0] += 1
        }
        return hourCounts.max(by: { $0.value < $1.value })?.key
    }
}

/// Filter options for activity log
public enum ActivityFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case creates = "Creates"
    case updates = "Updates"
    case deletes = "Deletes"
    case completes = "Completes"
    case views = "Views"
    case searches = "Searches"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .creates: return "plus.circle"
        case .updates: return "pencil.circle"
        case .deletes: return "trash"
        case .completes: return "checkmark.circle"
        case .views: return "eye"
        case .searches: return "magnifyingglass"
        }
    }
}

/// Date range options for activity log
public enum ActivityDateRange: String, CaseIterable, Identifiable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case allTime = "All Time"

    public var id: String { rawValue }
}
