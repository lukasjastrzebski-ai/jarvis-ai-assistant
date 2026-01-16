import Foundation

/// Calendar event model
public struct CalendarEvent: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var calendarId: String
    public var title: String
    public var description: String?
    public var location: String?
    public var startDate: Date
    public var endDate: Date
    public var isAllDay: Bool
    public var attendees: [EventAttendee]
    public var recurrence: EventRecurrence?
    public var reminders: [EventReminder]
    public var status: EventStatus
    public var conferenceLink: String?

    public init(
        id: String = UUID().uuidString,
        calendarId: String,
        title: String,
        description: String? = nil,
        location: String? = nil,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        attendees: [EventAttendee] = [],
        recurrence: EventRecurrence? = nil,
        reminders: [EventReminder] = [],
        status: EventStatus = .confirmed,
        conferenceLink: String? = nil
    ) {
        self.id = id
        self.calendarId = calendarId
        self.title = title
        self.description = description
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.attendees = attendees
        self.recurrence = recurrence
        self.reminders = reminders
        self.status = status
        self.conferenceLink = conferenceLink
    }
}

/// Event attendee
public struct EventAttendee: Codable, Equatable, Sendable {
    public let email: String
    public var name: String?
    public var status: AttendeeStatus
    public var isOrganizer: Bool

    public init(email: String, name: String? = nil, status: AttendeeStatus = .needsAction, isOrganizer: Bool = false) {
        self.email = email
        self.name = name
        self.status = status
        self.isOrganizer = isOrganizer
    }
}

/// Attendee response status
public enum AttendeeStatus: String, Codable, Sendable {
    case needsAction
    case declined
    case tentative
    case accepted
}

/// Event status
public enum EventStatus: String, Codable, Sendable {
    case confirmed
    case tentative
    case cancelled
}

/// Event recurrence rule
public struct EventRecurrence: Codable, Equatable, Sendable {
    public let frequency: RecurrenceFrequency
    public let interval: Int
    public let until: Date?
    public let count: Int?

    public init(frequency: RecurrenceFrequency, interval: Int = 1, until: Date? = nil, count: Int? = nil) {
        self.frequency = frequency
        self.interval = interval
        self.until = until
        self.count = count
    }
}

/// Recurrence frequency
public enum RecurrenceFrequency: String, Codable, Sendable {
    case daily
    case weekly
    case monthly
    case yearly
}

/// Event reminder
public struct EventReminder: Codable, Equatable, Sendable {
    public let method: ReminderMethod
    public let minutesBefore: Int

    public init(method: ReminderMethod, minutesBefore: Int) {
        self.method = method
        self.minutesBefore = minutesBefore
    }
}

/// Reminder delivery method
public enum ReminderMethod: String, Codable, Sendable {
    case notification
    case email
}

/// Calendar model
public struct Calendar: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var color: String
    public var isDefault: Bool
    public var isReadOnly: Bool
    public var accountType: CalendarAccountType

    public init(
        id: String = UUID().uuidString,
        name: String,
        color: String = "#007AFF",
        isDefault: Bool = false,
        isReadOnly: Bool = false,
        accountType: CalendarAccountType = .local
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.isDefault = isDefault
        self.isReadOnly = isReadOnly
        self.accountType = accountType
    }
}

/// Calendar account types
public enum CalendarAccountType: String, Codable, Sendable {
    case local
    case apple
    case google
    case exchange
}

/// Service for calendar operations
public actor CalendarService {
    private var calendars: [Calendar] = []
    private var events: [String: [CalendarEvent]] = [:] // calendarId -> events
    private var observers: [UUID: (CalendarEvent) -> Void] = [:]

    public enum CalendarError: Error, LocalizedError {
        case notAuthorized
        case calendarNotFound
        case eventNotFound
        case createFailed(String)
        case updateFailed(String)
        case deleteFailed(String)
        case conflictDetected([CalendarEvent])

        public var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Calendar access not authorized"
            case .calendarNotFound:
                return "Calendar not found"
            case .eventNotFound:
                return "Event not found"
            case .createFailed(let message):
                return "Failed to create event: \(message)"
            case .updateFailed(let message):
                return "Failed to update event: \(message)"
            case .deleteFailed(let message):
                return "Failed to delete event: \(message)"
            case .conflictDetected(let events):
                return "Conflict detected with \(events.count) event(s)"
            }
        }
    }

    public init() {}

    // MARK: - Calendar Management

    /// Add a calendar
    public func addCalendar(_ calendar: Calendar) {
        if !calendars.contains(where: { $0.id == calendar.id }) {
            calendars.append(calendar)
            events[calendar.id] = []
        }
    }

    /// Get all calendars
    public func getCalendars() -> [Calendar] {
        return calendars
    }

    /// Remove a calendar
    public func removeCalendar(id: String) {
        calendars.removeAll { $0.id == id }
        events.removeValue(forKey: id)
    }

    // MARK: - Event Operations

    /// Create a new event
    public func createEvent(_ event: CalendarEvent) async throws -> CalendarEvent {
        guard calendars.contains(where: { $0.id == event.calendarId }) else {
            throw CalendarError.calendarNotFound
        }

        // Check for conflicts
        let conflicts = try await checkConflicts(event)
        if !conflicts.isEmpty {
            throw CalendarError.conflictDetected(conflicts)
        }

        var calendarEvents = events[event.calendarId] ?? []
        calendarEvents.append(event)
        events[event.calendarId] = calendarEvents

        notifyObservers(event)
        return event
    }

    /// Update an event
    public func updateEvent(_ event: CalendarEvent) async throws {
        guard var calendarEvents = events[event.calendarId],
              let index = calendarEvents.firstIndex(where: { $0.id == event.id }) else {
            throw CalendarError.eventNotFound
        }

        calendarEvents[index] = event
        events[event.calendarId] = calendarEvents

        notifyObservers(event)
    }

    /// Delete an event
    public func deleteEvent(eventId: String, calendarId: String) async throws {
        guard var calendarEvents = events[calendarId] else {
            throw CalendarError.calendarNotFound
        }

        calendarEvents.removeAll { $0.id == eventId }
        events[calendarId] = calendarEvents
    }

    /// Get event by ID
    public func getEvent(eventId: String, calendarId: String) -> CalendarEvent? {
        return events[calendarId]?.first { $0.id == eventId }
    }

    // MARK: - Queries

    /// Get events for a date range
    public func getEvents(from startDate: Date, to endDate: Date) -> [CalendarEvent] {
        var allEvents: [CalendarEvent] = []
        for calendarEvents in events.values {
            let filtered = calendarEvents.filter { event in
                event.startDate >= startDate && event.startDate <= endDate
            }
            allEvents.append(contentsOf: filtered)
        }
        return allEvents.sorted { $0.startDate < $1.startDate }
    }

    /// Get events for a specific day
    public func getEventsForDay(_ date: Date) -> [CalendarEvent] {
        let calendar = Foundation.Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        return getEvents(from: startOfDay, to: endOfDay)
    }

    /// Get today's events
    public func getTodaysEvents() -> [CalendarEvent] {
        return getEventsForDay(Date())
    }

    /// Get upcoming events
    public func getUpcomingEvents(limit: Int = 10) -> [CalendarEvent] {
        let now = Date()
        var allEvents: [CalendarEvent] = []

        for calendarEvents in events.values {
            let upcoming = calendarEvents.filter { $0.startDate > now }
            allEvents.append(contentsOf: upcoming)
        }

        return Array(allEvents.sorted { $0.startDate < $1.startDate }.prefix(limit))
    }

    /// Get next event
    public func getNextEvent() -> CalendarEvent? {
        return getUpcomingEvents(limit: 1).first
    }

    // MARK: - Availability

    /// Check availability for a time range
    public func checkAvailability(from start: Date, to end: Date) -> Bool {
        let conflicting = getEvents(from: start, to: end)
        return conflicting.isEmpty
    }

    /// Find free slots in a day
    public func findFreeSlots(on date: Date, duration: TimeInterval) -> [(start: Date, end: Date)] {
        let calendar = Foundation.Calendar.current
        let workdayStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date)!
        let workdayEnd = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: date)!

        let dayEvents = getEventsForDay(date).sorted { $0.startDate < $1.startDate }

        var freeSlots: [(start: Date, end: Date)] = []
        var currentStart = workdayStart

        for event in dayEvents {
            if event.startDate > currentStart {
                let gap = event.startDate.timeIntervalSince(currentStart)
                if gap >= duration {
                    freeSlots.append((start: currentStart, end: event.startDate))
                }
            }
            currentStart = max(currentStart, event.endDate)
        }

        // Check remaining time after last event
        if workdayEnd > currentStart {
            let gap = workdayEnd.timeIntervalSince(currentStart)
            if gap >= duration {
                freeSlots.append((start: currentStart, end: workdayEnd))
            }
        }

        return freeSlots
    }

    /// Check for conflicts with an event
    public func checkConflicts(_ event: CalendarEvent) async throws -> [CalendarEvent] {
        // An event conflicts if it overlaps: event1.start < event2.end && event2.start < event1.end
        var allEvents: [CalendarEvent] = []
        for calendarEvents in events.values {
            let overlapping = calendarEvents.filter { existing in
                existing.id != event.id &&
                existing.startDate < event.endDate &&
                event.startDate < existing.endDate
            }
            allEvents.append(contentsOf: overlapping)
        }
        return allEvents
    }

    // MARK: - Sync

    /// Sync with external calendar providers
    public func sync() async throws {
        // In production, this would sync with Apple Calendar, Google Calendar, etc.
        // For now, just a placeholder
    }

    // MARK: - Observers

    /// Add an observer for event changes
    public func addObserver(id: UUID, handler: @escaping @Sendable (CalendarEvent) -> Void) {
        observers[id] = handler
    }

    /// Remove an observer
    public func removeObserver(id: UUID) {
        observers.removeValue(forKey: id)
    }

    private func notifyObservers(_ event: CalendarEvent) {
        for handler in observers.values {
            handler(event)
        }
    }
}
