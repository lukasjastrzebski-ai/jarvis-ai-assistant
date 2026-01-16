import XCTest
@testable import JarvisCore

final class DailyPlanningServiceTests: XCTestCase {
    var service: DailyPlanningService!

    override func setUp() async throws {
        service = DailyPlanningService()
    }

    // MARK: - Plan Generation Tests

    func testGeneratePlanWithItems() async {
        let userId = UUID()
        let items = [
            Item(userId: userId, title: "High priority task", priority: .high),
            Item(userId: userId, title: "Medium task", priority: .medium),
            Item(userId: userId, title: "Low task", priority: .low)
        ]

        let plan = await service.generateTodaysPlan(items: items, calendarEvents: [])

        XCTAssertFalse(plan.outcomes.isEmpty)
        XCTAssertEqual(plan.status, .draft)
    }

    func testGeneratePlanLimitsToFiveOutcomes() async {
        // Create 10 items
        let userId = UUID()
        let items = (1...10).map { i in
            Item(userId: userId, title: "Task \(i)", priority: .high)
        }

        let plan = await service.generateTodaysPlan(items: items, calendarEvents: [])

        XCTAssertLessThanOrEqual(plan.outcomes.count, 5)
    }

    func testGeneratePlanSortsByPriority() async {
        let userId = UUID()
        let items = [
            Item(userId: userId, title: "Low task", priority: .low),
            Item(userId: userId, title: "High task", priority: .high),
            Item(userId: userId, title: "Medium task", priority: .medium)
        ]

        let plan = await service.generateTodaysPlan(items: items, calendarEvents: [])

        // First outcome should be highest priority
        if let first = plan.outcomes.first {
            XCTAssertEqual(first.title, "High task")
        }
    }

    func testGeneratePlanIncludesCalendarEvents() async {
        let event = CalendarEvent(
            calendarId: "cal-1",
            title: "Team Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600)
        )

        let plan = await service.generatePlan(for: Date(), items: [], calendarEvents: [event])

        XCTAssertEqual(plan.calendarEvents.count, 1)
        XCTAssertEqual(plan.calendarEvents.first?.title, "Team Meeting")
    }

    func testGeneratePlanCalculatesAvailableTime() async {
        // 2-hour meeting should reduce available time
        let event = CalendarEvent(
            calendarId: "cal-1",
            title: "Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(7200) // 2 hours
        )

        let plan = await service.generatePlan(for: Date(), items: [], calendarEvents: [event])

        // Default workday is 8 hours (480 min), minus 2 hours (120 min) = 360 min
        XCTAssertEqual(plan.availableMinutes, 360)
    }

    func testGeneratePlanDetectsOverload() async {
        // Create many high priority items that will exceed available time
        // With default 30 min each, 5 items = 150 min
        // Create items that, combined with a long meeting, exceed available time
        let userId = UUID()
        let items = (1...10).map { i in
            Item(userId: userId, title: "Long task \(i)", priority: .high)
        }

        // Add a meeting that takes up most of the day (7 hours)
        let event = CalendarEvent(
            calendarId: "cal-1",
            title: "All-day meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(25200) // 7 hours
        )

        let plan = await service.generatePlan(for: Date(), items: items, calendarEvents: [event])

        // 8 hour workday - 7 hour meeting = 60 min available
        // 5 outcomes * 30 min = 150 min planned
        XCTAssertTrue(plan.isOverloaded)
        XCTAssertTrue(plan.warnings.contains { $0.type == .overloaded })
    }

    // MARK: - Plan Retrieval Tests

    func testGetPlanForDate() async {
        let userId = UUID()
        let items = [Item(userId: userId, title: "Test", priority: .medium)]
        _ = await service.generateTodaysPlan(items: items, calendarEvents: [])

        let retrieved = await service.getTodaysPlan()

        XCTAssertNotNil(retrieved)
    }

    func testGetPlanReturnsNilForMissingDate() async {
        let tomorrow = Foundation.Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let plan = await service.getPlan(for: tomorrow)

        XCTAssertNil(plan)
    }

    // MARK: - Plan Modification Tests

    func testAcceptPlan() async throws {
        let userId = UUID()
        let items = [Item(userId: userId, title: "Test", priority: .medium)]
        let plan = await service.generateTodaysPlan(items: items, calendarEvents: [])

        try await service.acceptPlan(planId: plan.id)

        let updated = await service.getTodaysPlan()
        XCTAssertEqual(updated?.status, .accepted)
    }

    func testCompleteOutcome() async throws {
        let userId = UUID()
        let items = [Item(userId: userId, title: "Test task", priority: .high)]
        let plan = await service.generateTodaysPlan(items: items, calendarEvents: [])
        let outcomeId = plan.outcomes.first!.id

        try await service.completeOutcome(outcomeId: outcomeId, in: plan.id)

        let updated = await service.getTodaysPlan()
        XCTAssertTrue(updated?.outcomes.first?.isCompleted ?? false)
    }

    func testCompletingAllOutcomesCompletesPlan() async throws {
        let userId = UUID()
        let items = [Item(userId: userId, title: "Single task", priority: .high)]
        let plan = await service.generateTodaysPlan(items: items, calendarEvents: [])
        try await service.acceptPlan(planId: plan.id)

        let outcomeId = plan.outcomes.first!.id
        try await service.completeOutcome(outcomeId: outcomeId, in: plan.id)

        let updated = await service.getTodaysPlan()
        XCTAssertEqual(updated?.status, .completed)
    }

    func testAddOutcome() async throws {
        let plan = await service.generateTodaysPlan(items: [], calendarEvents: [])
        let outcome = PlannedOutcome(title: "New outcome", estimatedMinutes: 45)

        try await service.addOutcome(outcome, to: plan.id)

        let updated = await service.getTodaysPlan()
        XCTAssertEqual(updated?.outcomes.count, 1)
        XCTAssertEqual(updated?.outcomes.first?.title, "New outcome")
    }

    func testRemoveOutcome() async throws {
        let userId = UUID()
        let items = [Item(userId: userId, title: "To remove", priority: .high)]
        let plan = await service.generateTodaysPlan(items: items, calendarEvents: [])
        let outcomeId = plan.outcomes.first!.id

        try await service.removeOutcome(outcomeId: outcomeId, from: plan.id)

        let updated = await service.getTodaysPlan()
        XCTAssertTrue(updated?.outcomes.isEmpty ?? false)
    }

    func testReorderOutcomes() async throws {
        let userId = UUID()
        let items = [
            Item(userId: userId, title: "First", priority: .high),
            Item(userId: userId, title: "Second", priority: .high),
            Item(userId: userId, title: "Third", priority: .high)
        ]
        let plan = await service.generateTodaysPlan(items: items, calendarEvents: [])

        try await service.reorderOutcomes(from: 2, to: 0, in: plan.id)

        let updated = await service.getTodaysPlan()
        // After moving index 2 to 0, that item should be first
        XCTAssertEqual(updated?.outcomes.count, 3)
    }

    // MARK: - Time Block Tests

    func testSuggestTimeBlocks() async {
        let outcome = PlannedOutcome(title: "Task", estimatedMinutes: 60)
        let today = Date()

        let suggestions = await service.suggestTimeBlocks(for: outcome, on: today, avoiding: [])

        XCTAssertFalse(suggestions.isEmpty)
    }

    func testSuggestTimeBlocksAvoidsEvents() async {
        let calendar = Foundation.Calendar.current
        let today = Date()

        // Create event from 10 AM to 11 AM
        let eventStart = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today)!
        let eventEnd = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: today)!

        let event = CalendarEventSummary(
            id: "1",
            title: "Meeting",
            startTime: eventStart,
            endTime: eventEnd
        )

        let outcome = PlannedOutcome(title: "Task", estimatedMinutes: 60)

        let suggestions = await service.suggestTimeBlocks(for: outcome, on: today, avoiding: [event])

        // No suggestion should overlap with the meeting
        for block in suggestions {
            XCTAssertFalse(
                block.start < eventEnd && eventStart < block.end,
                "Block should not overlap with meeting"
            )
        }
    }

    // MARK: - Model Tests

    func testPlannedOutcomePriorityScore() {
        let highUrgencyHighImportance = PlannedOutcome(
            title: "Test",
            urgency: .critical,
            importance: .critical
        )

        let lowUrgencyLowImportance = PlannedOutcome(
            title: "Test",
            urgency: .low,
            importance: .low
        )

        XCTAssertGreaterThan(highUrgencyHighImportance.priorityScore, lowUrgencyLowImportance.priorityScore)
    }

    func testDailyPlanProgress() {
        var plan = DailyPlan(
            date: Date(),
            outcomes: [
                PlannedOutcome(title: "Done", isCompleted: true),
                PlannedOutcome(title: "Not done", isCompleted: false)
            ]
        )

        XCTAssertEqual(plan.progressPercentage, 50)
    }

    func testTimeBlockDuration() {
        let start = Date()
        let end = start.addingTimeInterval(3600) // 1 hour
        let block = TimeBlock(start: start, end: end)

        XCTAssertEqual(block.durationMinutes, 60)
    }

    func testPlanWarningInit() {
        let warning = PlanWarning(
            type: .overloaded,
            message: "Test message",
            suggestion: "Test suggestion"
        )

        XCTAssertEqual(warning.type, .overloaded)
        XCTAssertEqual(warning.message, "Test message")
        XCTAssertEqual(warning.suggestion, "Test suggestion")
    }

    func testCalendarEventSummaryDuration() {
        let start = Date()
        let end = start.addingTimeInterval(5400) // 90 minutes
        let summary = CalendarEventSummary(
            id: "1",
            title: "Meeting",
            startTime: start,
            endTime: end
        )

        XCTAssertEqual(summary.durationMinutes, 90)
    }

    // MARK: - Error Tests

    func testAcceptPlanNotFoundError() async {
        do {
            try await service.acceptPlan(planId: UUID())
            XCTFail("Should throw error")
        } catch let error as DailyPlanningService.PlanningError {
            XCTAssertEqual(error, .planNotFound)
        } catch {
            XCTFail("Wrong error type")
        }
    }

    func testCompleteOutcomeNotFoundError() async throws {
        let userId = UUID()
        let items = [Item(userId: userId, title: "Test", priority: .medium)]
        let plan = await service.generateTodaysPlan(items: items, calendarEvents: [])

        do {
            try await service.completeOutcome(outcomeId: UUID(), in: plan.id)
            XCTFail("Should throw error")
        } catch let error as DailyPlanningService.PlanningError {
            XCTAssertEqual(error, .outcomeNotFound)
        }
    }

    func testPlanningErrorDescriptions() {
        let notFound = DailyPlanningService.PlanningError.planNotFound
        XCTAssertTrue(notFound.errorDescription?.contains("not found") ?? false)

        let outcomeNotFound = DailyPlanningService.PlanningError.outcomeNotFound
        XCTAssertTrue(outcomeNotFound.errorDescription?.contains("Outcome") ?? false)

        let invalidIndex = DailyPlanningService.PlanningError.invalidIndex
        XCTAssertTrue(invalidIndex.errorDescription?.contains("index") ?? false)
    }

    // MARK: - Urgency/Importance Level Tests

    func testUrgencyLevelComparable() {
        XCTAssertTrue(PlannedOutcome.UrgencyLevel.low < PlannedOutcome.UrgencyLevel.medium)
        XCTAssertTrue(PlannedOutcome.UrgencyLevel.medium < PlannedOutcome.UrgencyLevel.high)
        XCTAssertTrue(PlannedOutcome.UrgencyLevel.high < PlannedOutcome.UrgencyLevel.critical)
    }

    func testImportanceLevelComparable() {
        XCTAssertTrue(PlannedOutcome.ImportanceLevel.low < PlannedOutcome.ImportanceLevel.medium)
        XCTAssertTrue(PlannedOutcome.ImportanceLevel.medium < PlannedOutcome.ImportanceLevel.high)
        XCTAssertTrue(PlannedOutcome.ImportanceLevel.high < PlannedOutcome.ImportanceLevel.critical)
    }
}
