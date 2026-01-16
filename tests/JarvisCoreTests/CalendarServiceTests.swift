import XCTest
@testable import JarvisCore

final class CalendarServiceTests: XCTestCase {
    var service: CalendarService!
    let testCalendar = JarvisCore.Calendar(name: "Test Calendar")

    override func setUp() async throws {
        service = CalendarService()
        await service.addCalendar(testCalendar)
    }

    // MARK: - Calendar Management Tests

    func testAddCalendar() async {
        let calendars = await service.getCalendars()
        XCTAssertEqual(calendars.count, 1)
        XCTAssertEqual(calendars.first?.name, "Test Calendar")
    }

    func testRemoveCalendar() async {
        await service.removeCalendar(id: testCalendar.id)
        let calendars = await service.getCalendars()
        XCTAssertTrue(calendars.isEmpty)
    }

    // MARK: - Event Operations Tests

    func testCreateEvent() async throws {
        let event = CalendarEvent(
            calendarId: testCalendar.id,
            title: "Test Meeting",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600)
        )

        let created = try await service.createEvent(event)

        XCTAssertEqual(created.title, "Test Meeting")
        XCTAssertEqual(created.calendarId, testCalendar.id)
    }

    func testUpdateEvent() async throws {
        let event = CalendarEvent(
            calendarId: testCalendar.id,
            title: "Original",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600)
        )
        _ = try await service.createEvent(event)

        var updated = event
        updated.title = "Updated"
        try await service.updateEvent(updated)

        let fetched = await service.getEvent(eventId: event.id, calendarId: testCalendar.id)
        XCTAssertEqual(fetched?.title, "Updated")
    }

    func testDeleteEvent() async throws {
        let event = CalendarEvent(
            calendarId: testCalendar.id,
            title: "To Delete",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600)
        )
        _ = try await service.createEvent(event)

        try await service.deleteEvent(eventId: event.id, calendarId: testCalendar.id)

        let fetched = await service.getEvent(eventId: event.id, calendarId: testCalendar.id)
        XCTAssertNil(fetched)
    }

    // MARK: - Query Tests

    func testGetEventsForDay() async throws {
        let today = Date()
        let event = CalendarEvent(
            calendarId: testCalendar.id,
            title: "Today's Event",
            startDate: today,
            endDate: today.addingTimeInterval(3600)
        )
        _ = try await service.createEvent(event)

        let events = await service.getEventsForDay(today)
        XCTAssertEqual(events.count, 1)
    }

    func testGetTodaysEvents() async throws {
        let today = Date()
        let event = CalendarEvent(
            calendarId: testCalendar.id,
            title: "Today",
            startDate: today.addingTimeInterval(3600),
            endDate: today.addingTimeInterval(7200)
        )
        _ = try await service.createEvent(event)

        let events = await service.getTodaysEvents()
        XCTAssertGreaterThanOrEqual(events.count, 1)
    }

    func testGetUpcomingEvents() async throws {
        let future = Date().addingTimeInterval(86400) // Tomorrow
        let event = CalendarEvent(
            calendarId: testCalendar.id,
            title: "Future Event",
            startDate: future,
            endDate: future.addingTimeInterval(3600)
        )
        _ = try await service.createEvent(event)

        let upcoming = await service.getUpcomingEvents(limit: 10)
        XCTAssertGreaterThanOrEqual(upcoming.count, 1)
    }

    func testGetNextEvent() async throws {
        let future = Date().addingTimeInterval(86400)
        let event = CalendarEvent(
            calendarId: testCalendar.id,
            title: "Next",
            startDate: future,
            endDate: future.addingTimeInterval(3600)
        )
        _ = try await service.createEvent(event)

        let next = await service.getNextEvent()
        XCTAssertNotNil(next)
        XCTAssertEqual(next?.title, "Next")
    }

    // MARK: - Availability Tests

    func testCheckAvailability() async throws {
        let start = Date().addingTimeInterval(86400)
        let end = start.addingTimeInterval(3600)

        let isAvailable = await service.checkAvailability(from: start, to: end)
        XCTAssertTrue(isAvailable)

        // Create conflicting event
        let event = CalendarEvent(
            calendarId: testCalendar.id,
            title: "Busy",
            startDate: start,
            endDate: end
        )
        _ = try await service.createEvent(event)

        let stillAvailable = await service.checkAvailability(from: start, to: end)
        XCTAssertFalse(stillAvailable)
    }

    func testFindFreeSlots() async throws {
        let tomorrow = Foundation.Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let freeSlots = await service.findFreeSlots(on: tomorrow, duration: 3600)
        XCTAssertFalse(freeSlots.isEmpty)
    }

    func testCheckConflicts() async throws {
        let start = Date().addingTimeInterval(86400)
        let end = start.addingTimeInterval(3600)

        // Create first event
        let event1 = CalendarEvent(
            calendarId: testCalendar.id,
            title: "Event 1",
            startDate: start,
            endDate: end
        )
        _ = try await service.createEvent(event1)

        // Check conflict with overlapping event
        let event2 = CalendarEvent(
            calendarId: testCalendar.id,
            title: "Event 2",
            startDate: start.addingTimeInterval(1800), // 30 min later
            endDate: end.addingTimeInterval(1800)
        )

        let conflicts = try await service.checkConflicts(event2)
        XCTAssertFalse(conflicts.isEmpty)
    }

    // MARK: - Model Tests

    func testCalendarEventInit() {
        let event = CalendarEvent(
            calendarId: "cal-1",
            title: "Meeting",
            description: "Discuss project",
            location: "Room 1",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            isAllDay: false,
            status: .confirmed
        )

        XCTAssertEqual(event.title, "Meeting")
        XCTAssertEqual(event.description, "Discuss project")
        XCTAssertEqual(event.location, "Room 1")
        XCTAssertEqual(event.status, .confirmed)
    }

    func testEventAttendee() {
        let attendee = EventAttendee(
            email: "test@example.com",
            name: "Test User",
            status: .accepted,
            isOrganizer: true
        )

        XCTAssertEqual(attendee.email, "test@example.com")
        XCTAssertEqual(attendee.status, .accepted)
        XCTAssertTrue(attendee.isOrganizer)
    }

    func testEventRecurrence() {
        let recurrence = EventRecurrence(frequency: .weekly, interval: 2, count: 10)

        XCTAssertEqual(recurrence.frequency, .weekly)
        XCTAssertEqual(recurrence.interval, 2)
        XCTAssertEqual(recurrence.count, 10)
    }

    func testCalendarErrorDescriptions() {
        let notAuth = CalendarService.CalendarError.notAuthorized
        XCTAssertTrue(notAuth.errorDescription?.contains("not authorized") ?? false)

        let notFound = CalendarService.CalendarError.calendarNotFound
        XCTAssertTrue(notFound.errorDescription?.contains("not found") ?? false)

        let conflict = CalendarService.CalendarError.conflictDetected([])
        XCTAssertTrue(conflict.errorDescription?.contains("Conflict") ?? false)
    }
}
