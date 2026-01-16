import Foundation
import JarvisCore

/// ViewModel for daily planning view
@MainActor
public class DailyPlanViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published public var currentPlan: DailyPlan?
    @Published public var isLoading: Bool = false
    @Published public var error: String?
    @Published public var selectedOutcome: PlannedOutcome?
    @Published public var showingAddOutcome: Bool = false
    @Published public var showingWarnings: Bool = false

    // Items to plan (can be set externally)
    @Published public var items: [Item] = []

    // MARK: - Dependencies

    private let planningService: DailyPlanningService
    private let calendarService: CalendarService

    // MARK: - Initialization

    public init(
        planningService: DailyPlanningService = DailyPlanningService(),
        calendarService: CalendarService = CalendarService()
    ) {
        self.planningService = planningService
        self.calendarService = calendarService
    }

    // MARK: - Computed Properties

    public var hasWarnings: Bool {
        currentPlan?.warnings.isEmpty == false
    }

    public var progressPercentage: Int {
        currentPlan?.progressPercentage ?? 0
    }

    public var completedCount: Int {
        currentPlan?.outcomes.filter { $0.isCompleted }.count ?? 0
    }

    public var totalCount: Int {
        currentPlan?.outcomes.count ?? 0
    }

    public var isOverloaded: Bool {
        currentPlan?.isOverloaded ?? false
    }

    public var formattedDate: String {
        guard let date = currentPlan?.date else { return "Today" }
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    public var availableTimeFormatted: String {
        guard let plan = currentPlan else { return "-" }
        let hours = plan.availableMinutes / 60
        let minutes = plan.availableMinutes % 60
        if minutes == 0 {
            return "\(hours)h available"
        }
        return "\(hours)h \(minutes)m available"
    }

    public var plannedTimeFormatted: String {
        guard let plan = currentPlan else { return "-" }
        let hours = plan.totalPlannedMinutes / 60
        let minutes = plan.totalPlannedMinutes % 60
        if minutes == 0 {
            return "\(hours)h planned"
        }
        return "\(hours)h \(minutes)m planned"
    }

    // MARK: - Actions

    /// Set items to include in planning
    public func setItems(_ items: [Item]) {
        self.items = items
    }

    /// Generate today's plan
    public func generatePlan() async {
        isLoading = true
        error = nil

        // Fetch calendar events
        let events = await calendarService.getTodaysEvents()

        // Generate plan using the items that have been set
        currentPlan = await planningService.generateTodaysPlan(
            items: items,
            calendarEvents: events
        )

        isLoading = false
    }

    /// Load existing plan for today
    public func loadTodaysPlan() async {
        isLoading = true
        error = nil

        if let existingPlan = await planningService.getTodaysPlan() {
            currentPlan = existingPlan
        } else {
            await generatePlan()
        }

        isLoading = false
    }

    /// Accept the current plan
    public func acceptPlan() async {
        guard let plan = currentPlan else { return }

        do {
            try await planningService.acceptPlan(planId: plan.id)
            await refreshPlan()
        } catch {
            self.error = "Failed to accept plan: \(error.localizedDescription)"
        }
    }

    /// Complete an outcome
    public func completeOutcome(_ outcome: PlannedOutcome) async {
        guard let plan = currentPlan else { return }

        do {
            try await planningService.completeOutcome(outcomeId: outcome.id, in: plan.id)
            await refreshPlan()
        } catch {
            self.error = "Failed to complete outcome: \(error.localizedDescription)"
        }
    }

    /// Add a new outcome to the plan
    public func addOutcome(title: String, estimatedMinutes: Int, urgency: PlannedOutcome.UrgencyLevel) async {
        guard let plan = currentPlan else { return }

        let outcome = PlannedOutcome(
            title: title,
            urgency: urgency,
            importance: .medium,
            estimatedMinutes: estimatedMinutes,
            sourceType: .manual
        )

        do {
            try await planningService.addOutcome(outcome, to: plan.id)
            await refreshPlan()
            showingAddOutcome = false
        } catch {
            self.error = "Failed to add outcome: \(error.localizedDescription)"
        }
    }

    /// Remove an outcome from the plan
    public func removeOutcome(_ outcome: PlannedOutcome) async {
        guard let plan = currentPlan else { return }

        do {
            try await planningService.removeOutcome(outcomeId: outcome.id, from: plan.id)
            await refreshPlan()
        } catch {
            self.error = "Failed to remove outcome: \(error.localizedDescription)"
        }
    }

    /// Reorder outcomes
    public func moveOutcome(from source: IndexSet, to destination: Int) async {
        guard let plan = currentPlan,
              let sourceIndex = source.first else { return }

        do {
            try await planningService.reorderOutcomes(
                from: sourceIndex,
                to: destination,
                in: plan.id
            )
            await refreshPlan()
        } catch {
            self.error = "Failed to reorder outcomes: \(error.localizedDescription)"
        }
    }

    /// Refresh the current plan
    public func refreshPlan() async {
        guard let plan = currentPlan else { return }

        if let updated = await planningService.getPlan(for: plan.date) {
            currentPlan = updated
        }
    }

    /// Get time block suggestions for an outcome
    public func getTimeBlockSuggestions(for outcome: PlannedOutcome) async -> [TimeBlock] {
        guard let plan = currentPlan else { return [] }

        return await planningService.suggestTimeBlocks(
            for: outcome,
            on: plan.date,
            avoiding: plan.calendarEvents
        )
    }

    /// Update an outcome's time block
    public func updateTimeBlock(_ timeBlock: TimeBlock?, for outcome: PlannedOutcome) async {
        guard let plan = currentPlan else { return }

        var updated = outcome
        updated.timeBlock = timeBlock

        do {
            try await planningService.updateOutcome(updated, in: plan.id)
            await refreshPlan()
        } catch {
            self.error = "Failed to update time block: \(error.localizedDescription)"
        }
    }

    /// Dismiss error
    public func dismissError() {
        error = nil
    }
}

// MARK: - Time Formatting Extension

public extension TimeBlock {
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}
