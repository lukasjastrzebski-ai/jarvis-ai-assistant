import Foundation

/// Mock calendar provider for integration testing without Apple/Google Calendar APIs
public actor MockCalendarProvider {
    private var mockCalendars: [JarvisCore.Calendar] = []
    private var mockEvents: [String: [CalendarEvent]] = [:]

    public init() {
        // Initialize data inline to avoid actor isolation warning
        let workCalendar = JarvisCore.Calendar(
            id: "work-calendar",
            name: "Work",
            color: "#007AFF",
            isDefault: true,
            accountType: .google
        )

        let personalCalendar = JarvisCore.Calendar(
            id: "personal-calendar",
            name: "Personal",
            color: "#34C759",
            accountType: .apple
        )

        mockCalendars = [workCalendar, personalCalendar]

        let calendar = Foundation.Calendar.current
        let today = Date()

        let todayEvents: [CalendarEvent] = [
            CalendarEvent(
                id: "event-1",
                calendarId: "work-calendar",
                title: "Team Standup",
                description: "Daily sync with the team",
                location: "Zoom",
                startDate: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today)!,
                conferenceLink: "https://zoom.us/j/123456"
            ),
            CalendarEvent(
                id: "event-2",
                calendarId: "work-calendar",
                title: "Product Review",
                description: "Review Q4 roadmap",
                location: "Conference Room A",
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today)!,
                attendees: [
                    EventAttendee(email: "pm@company.com", name: "Product Manager", status: .accepted),
                    EventAttendee(email: "eng@company.com", name: "Engineer", status: .tentative)
                ]
            ),
            CalendarEvent(
                id: "event-3",
                calendarId: "personal-calendar",
                title: "Gym",
                location: "Local Fitness",
                startDate: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today)!
            )
        ]

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let tomorrowEvents: [CalendarEvent] = [
            CalendarEvent(
                id: "event-4",
                calendarId: "work-calendar",
                title: "1:1 with Manager",
                startDate: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: tomorrow)!,
                endDate: calendar.date(bySettingHour: 11, minute: 30, second: 0, of: tomorrow)!
            ),
            CalendarEvent(
                id: "event-5",
                calendarId: "personal-calendar",
                title: "Dentist Appointment",
                location: "Downtown Dental",
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: tomorrow)!,
                endDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: tomorrow)!
            )
        ]

        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today)!
        let weeklyEvent = CalendarEvent(
            id: "event-6",
            calendarId: "work-calendar",
            title: "Weekly Planning",
            startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: nextWeek)!,
            endDate: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: nextWeek)!,
            recurrence: EventRecurrence(frequency: .weekly, interval: 1)
        )

        mockEvents["work-calendar"] = todayEvents.filter { $0.calendarId == "work-calendar" } +
                                       tomorrowEvents.filter { $0.calendarId == "work-calendar" } +
                                       [weeklyEvent]
        mockEvents["personal-calendar"] = todayEvents.filter { $0.calendarId == "personal-calendar" } +
                                          tomorrowEvents.filter { $0.calendarId == "personal-calendar" }
    }

    private func seedTestData() {
        // Kept for potential future use - init now handles seeding
        // Create mock calendars
        let workCalendar = JarvisCore.Calendar(
            id: "work-calendar",
            name: "Work",
            color: "#007AFF",
            isDefault: true,
            accountType: .google
        )

        let personalCalendar = JarvisCore.Calendar(
            id: "personal-calendar",
            name: "Personal",
            color: "#34C759",
            accountType: .apple
        )

        mockCalendars = [workCalendar, personalCalendar]

        // Create mock events for today and upcoming days
        let calendar = Foundation.Calendar.current
        let today = Date()

        // Today's events
        let todayEvents: [CalendarEvent] = [
            CalendarEvent(
                id: "event-1",
                calendarId: "work-calendar",
                title: "Team Standup",
                description: "Daily sync with the team",
                location: "Zoom",
                startDate: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today)!,
                conferenceLink: "https://zoom.us/j/123456"
            ),
            CalendarEvent(
                id: "event-2",
                calendarId: "work-calendar",
                title: "Product Review",
                description: "Review Q4 roadmap",
                location: "Conference Room A",
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: today)!,
                attendees: [
                    EventAttendee(email: "pm@company.com", name: "Product Manager", status: .accepted),
                    EventAttendee(email: "eng@company.com", name: "Engineer", status: .tentative)
                ]
            ),
            CalendarEvent(
                id: "event-3",
                calendarId: "personal-calendar",
                title: "Gym",
                location: "Local Fitness",
                startDate: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today)!
            )
        ]

        // Tomorrow's events
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let tomorrowEvents: [CalendarEvent] = [
            CalendarEvent(
                id: "event-4",
                calendarId: "work-calendar",
                title: "1:1 with Manager",
                startDate: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: tomorrow)!,
                endDate: calendar.date(bySettingHour: 11, minute: 30, second: 0, of: tomorrow)!
            ),
            CalendarEvent(
                id: "event-5",
                calendarId: "personal-calendar",
                title: "Dentist Appointment",
                location: "Downtown Dental",
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: tomorrow)!,
                endDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: tomorrow)!
            )
        ]

        // Next week recurring event
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: today)!
        let weeklyEvent = CalendarEvent(
            id: "event-6",
            calendarId: "work-calendar",
            title: "Weekly Planning",
            startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: nextWeek)!,
            endDate: calendar.date(bySettingHour: 11, minute: 0, second: 0, of: nextWeek)!,
            recurrence: EventRecurrence(frequency: .weekly, interval: 1)
        )

        mockEvents["work-calendar"] = todayEvents.filter { $0.calendarId == "work-calendar" } +
                                       tomorrowEvents.filter { $0.calendarId == "work-calendar" } +
                                       [weeklyEvent]
        mockEvents["personal-calendar"] = todayEvents.filter { $0.calendarId == "personal-calendar" } +
                                          tomorrowEvents.filter { $0.calendarId == "personal-calendar" }
    }

    // MARK: - Mock API Methods

    public func getCalendars() -> [JarvisCore.Calendar] {
        return mockCalendars
    }

    public func getEvents(for calendarId: String) -> [CalendarEvent] {
        return mockEvents[calendarId] ?? []
    }

    public func getAllEvents() -> [CalendarEvent] {
        return mockEvents.values.flatMap { $0 }.sorted { $0.startDate < $1.startDate }
    }

    public func getEventsForDay(_ date: Date) -> [CalendarEvent] {
        let calendar = Foundation.Calendar.current
        return getAllEvents().filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date)
        }
    }

    public func getTodaysEvents() -> [CalendarEvent] {
        return getEventsForDay(Date())
    }

    public func getUpcomingEvents(limit: Int = 10) -> [CalendarEvent] {
        let now = Date()
        return getAllEvents()
            .filter { $0.startDate > now }
            .prefix(limit)
            .map { $0 }
    }

    public func createEvent(_ event: CalendarEvent) {
        var events = mockEvents[event.calendarId] ?? []
        events.append(event)
        events.sort { $0.startDate < $1.startDate }
        mockEvents[event.calendarId] = events
    }

    public func deleteEvent(id: String, calendarId: String) {
        mockEvents[calendarId]?.removeAll { $0.id == id }
    }
}
