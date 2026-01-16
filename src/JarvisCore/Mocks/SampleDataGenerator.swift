import Foundation

/// Generates comprehensive sample data for app testing and demos
public class SampleDataGenerator {
    public static let shared = SampleDataGenerator()

    private init() {}

    // MARK: - Email Sample Data

    public func generateSampleEmails() -> [Email] {
        let now = Date()
        let calendar = Foundation.Calendar.current

        return [
            // Urgent work email - unread
            Email(
                id: "email-001",
                from: "sarah.chen@company.com",
                to: ["user@jarvis.app"],
                subject: "URGENT: Client presentation tomorrow",
                body: """
                Hi,

                Just a reminder that we have the client presentation tomorrow at 10 AM.
                Please make sure to review the latest deck and come prepared with the Q3 metrics.

                Key points to cover:
                - Revenue growth: 23% YoY
                - New customer acquisitions: 145
                - Churn reduction: down 12%

                Let me know if you need any additional data.

                Best,
                Sarah
                """,
                date: now.addingTimeInterval(-1800), // 30 mins ago
                isRead: false,
                labels: ["INBOX", "IMPORTANT"]
            ),

            // Team update - unread
            Email(
                id: "email-002",
                from: "mike.johnson@company.com",
                to: ["user@jarvis.app", "team@company.com"],
                cc: ["manager@company.com"],
                subject: "Sprint Review Notes - Week 3",
                body: """
                Team,

                Here's the summary from today's sprint review:

                Completed:
                ✅ User authentication module
                ✅ Dashboard redesign
                ✅ API rate limiting

                In Progress:
                🔄 Payment integration (80%)
                🔄 Email notifications (60%)

                Blocked:
                ⛔ Third-party API access (waiting on legal)

                Next sprint planning is Monday at 2 PM.

                -Mike
                """,
                date: now.addingTimeInterval(-7200), // 2 hours ago
                isRead: false,
                labels: ["INBOX", "WORK"]
            ),

            // Personal email - read
            Email(
                id: "email-003",
                from: "mom@family.com",
                to: ["user@jarvis.app"],
                subject: "Sunday dinner plans 🍽️",
                body: """
                Hi sweetie!

                Are you coming for dinner this Sunday? Your dad is making his famous lasagna!

                Grandma will be there too. She's been asking about you.

                Let me know by Friday so I can plan.

                Love,
                Mom

                P.S. Don't forget to bring that book you mentioned!
                """,
                date: now.addingTimeInterval(-14400), // 4 hours ago
                isRead: true,
                isStarred: true,
                labels: ["INBOX", "PERSONAL"]
            ),

            // Newsletter - read
            Email(
                id: "email-004",
                from: "digest@techcrunch.com",
                to: ["user@jarvis.app"],
                subject: "TechCrunch Daily: AI Startup Raises $100M",
                body: """
                TECHCRUNCH DAILY DIGEST

                🔥 TOP STORY
                AI startup Anthropic competitor raises $100M Series B
                The company claims their new model outperforms existing solutions...

                📱 MOBILE
                Apple announces iOS 18.2 with enhanced Siri
                New features include on-device AI processing...

                💰 FUNDING
                Fintech unicorn expands to Europe
                After dominating the US market, the payments company...

                Read more at techcrunch.com
                """,
                date: now.addingTimeInterval(-28800), // 8 hours ago
                isRead: true,
                labels: ["INBOX", "NEWSLETTERS"]
            ),

            // Meeting request - unread
            Email(
                id: "email-005",
                from: "calendar@google.com",
                to: ["user@jarvis.app"],
                subject: "Invitation: Product Roadmap Review",
                body: """
                You have been invited to:

                📅 Product Roadmap Review
                📍 Conference Room A / Google Meet
                🕐 Tomorrow, 2:00 PM - 3:30 PM

                Organizer: David Park (david.park@company.com)

                Attendees:
                - Sarah Chen
                - Mike Johnson
                - You

                Agenda:
                1. Q4 priorities review
                2. Resource allocation
                3. Timeline adjustments

                [Accept] [Decline] [Maybe]
                """,
                date: now.addingTimeInterval(-3600), // 1 hour ago
                isRead: false,
                labels: ["INBOX", "CALENDAR"]
            ),

            // E-commerce receipt - read
            Email(
                id: "email-006",
                from: "orders@amazon.com",
                to: ["user@jarvis.app"],
                subject: "Your order has shipped! 📦",
                body: """
                Your Amazon order has shipped!

                Order #123-4567890-1234567

                Items:
                - Wireless Bluetooth Headphones (1) - $79.99
                - USB-C Cable 3-Pack (1) - $12.99

                Estimated delivery: Thursday, January 18

                Track your package: amazon.com/track/ABC123

                Thank you for shopping with Amazon!
                """,
                date: calendar.date(byAdding: .day, value: -1, to: now)!,
                isRead: true,
                labels: ["INBOX", "PURCHASES"]
            ),

            // LinkedIn notification - read
            Email(
                id: "email-007",
                from: "notifications@linkedin.com",
                to: ["user@jarvis.app"],
                subject: "5 people viewed your profile",
                body: """
                Your weekly LinkedIn update

                👀 Profile views: 5 this week (+20%)
                🔍 Search appearances: 12
                📝 Post impressions: 234

                People who viewed your profile:
                - Senior Recruiter at Google
                - CTO at TechStartup Inc.
                - Engineering Manager at Meta

                See who's looking at your profile →
                """,
                date: calendar.date(byAdding: .day, value: -1, to: now)!,
                isRead: true,
                labels: ["INBOX", "SOCIAL"]
            ),

            // Bank alert - unread
            Email(
                id: "email-008",
                from: "alerts@chase.com",
                to: ["user@jarvis.app"],
                subject: "💳 Transaction Alert: $156.42",
                body: """
                Transaction Alert

                A transaction was made on your Chase card ending in 4521:

                Amount: $156.42
                Merchant: WHOLE FOODS MARKET
                Date: Today at 12:34 PM
                Location: San Francisco, CA

                If you don't recognize this transaction, please call us immediately.

                Chase Bank - We're here for you
                """,
                date: now.addingTimeInterval(-5400), // 1.5 hours ago
                isRead: false,
                labels: ["INBOX", "FINANCE"]
            ),

            // Friend email - read
            Email(
                id: "email-009",
                from: "alex.friend@gmail.com",
                to: ["user@jarvis.app"],
                subject: "Weekend hiking trip? 🏔️",
                body: """
                Hey!

                Want to do that Muir Woods hike this Saturday? Weather looks perfect!

                Plan:
                - Meet at 8 AM at the parking lot
                - 5-mile loop trail
                - Lunch at that cafe we saw last time

                Let me know if you're in! 🥾

                - Alex
                """,
                date: calendar.date(byAdding: .day, value: -2, to: now)!,
                isRead: true,
                isStarred: true,
                labels: ["INBOX", "PERSONAL"]
            ),

            // GitHub notification - read
            Email(
                id: "email-010",
                from: "notifications@github.com",
                to: ["user@jarvis.app"],
                subject: "[jarvis-ai] PR #127 merged: Add voice commands",
                body: """
                Pull Request merged

                Repository: jarvis-ai-assistant
                PR #127: Add voice commands feature

                Merged by: @contributor
                +523 additions, -45 deletions

                Files changed:
                - src/Voice/VoiceService.swift
                - src/Voice/VoiceCommands.swift
                - tests/VoiceServiceTests.swift

                View on GitHub →
                """,
                date: calendar.date(byAdding: .day, value: -2, to: now)!,
                isRead: true,
                labels: ["INBOX", "GITHUB"]
            )
        ]
    }

    // MARK: - Calendar Sample Data

    public func generateSampleEvents() -> [CalendarEvent] {
        let now = Date()
        let calendar = Foundation.Calendar.current
        let today = calendar.startOfDay(for: now)

        return [
            // Today's events
            CalendarEvent(
                id: "event-001",
                calendarId: "work-calendar",
                title: "Morning Standup",
                description: "Daily sync with the engineering team",
                location: "Zoom",
                startDate: calendar.date(bySettingHour: 9, minute: 30, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 9, minute: 45, second: 0, of: today)!,
                attendees: [
                    EventAttendee(email: "sarah@company.com", name: "Sarah Chen", status: .accepted),
                    EventAttendee(email: "mike@company.com", name: "Mike Johnson", status: .accepted)
                ],
                conferenceLink: "https://zoom.us/j/123456789"
            ),

            CalendarEvent(
                id: "event-002",
                calendarId: "work-calendar",
                title: "Client Presentation",
                description: "Q3 results presentation to Acme Corp",
                location: "Conference Room A",
                startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 11, minute: 30, second: 0, of: today)!,
                attendees: [
                    EventAttendee(email: "sarah@company.com", name: "Sarah Chen", status: .accepted),
                    EventAttendee(email: "client@acme.com", name: "John Client", status: .accepted)
                ]
            ),

            CalendarEvent(
                id: "event-003",
                calendarId: "work-calendar",
                title: "Lunch with Team",
                description: "Team bonding lunch",
                location: "Sushi Palace - 123 Main St",
                startDate: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 13, minute: 30, second: 0, of: today)!
            ),

            CalendarEvent(
                id: "event-004",
                calendarId: "work-calendar",
                title: "Product Roadmap Review",
                description: "Quarterly planning session",
                location: "Google Meet",
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: today)!,
                attendees: [
                    EventAttendee(email: "david@company.com", name: "David Park", status: .accepted),
                    EventAttendee(email: "lisa@company.com", name: "Lisa Wong", status: .tentative)
                ],
                conferenceLink: "https://meet.google.com/abc-defg-hij"
            ),

            CalendarEvent(
                id: "event-005",
                calendarId: "personal-calendar",
                title: "Gym - Leg Day 🏋️",
                description: "Don't skip leg day!",
                location: "FitLife Gym",
                startDate: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!,
                endDate: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today)!
            ),

            // Tomorrow's events
            CalendarEvent(
                id: "event-006",
                calendarId: "work-calendar",
                title: "1:1 with Manager",
                description: "Weekly check-in",
                startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 1, to: today)!)!,
                endDate: calendar.date(bySettingHour: 10, minute: 30, second: 0, of: calendar.date(byAdding: .day, value: 1, to: today)!)!,
                conferenceLink: "https://zoom.us/j/987654321"
            ),

            CalendarEvent(
                id: "event-007",
                calendarId: "personal-calendar",
                title: "Dentist Appointment",
                description: "Regular checkup",
                location: "Smile Dental - 456 Oak Ave",
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 1, to: today)!)!,
                endDate: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 1, to: today)!)!
            ),

            // This week events
            CalendarEvent(
                id: "event-008",
                calendarId: "work-calendar",
                title: "Sprint Planning",
                description: "Plan next sprint tasks",
                location: "Conference Room B",
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 3, to: today)!)!,
                endDate: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 3, to: today)!)!
            ),

            CalendarEvent(
                id: "event-009",
                calendarId: "personal-calendar",
                title: "Hiking with Alex 🥾",
                description: "Muir Woods trail",
                location: "Muir Woods Parking Lot",
                startDate: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 5, to: today)!)!,
                endDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 5, to: today)!)!
            ),

            CalendarEvent(
                id: "event-010",
                calendarId: "personal-calendar",
                title: "Family Dinner 🍽️",
                description: "Sunday dinner at parents' house",
                location: "Mom's House",
                startDate: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 6, to: today)!)!,
                endDate: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 6, to: today)!)!
            )
        ]
    }

    // MARK: - Memory Sample Data

    public func generateSampleMemories(userId: UUID) -> [Memory] {
        return [
            Memory(
                userId: userId,
                content: "Prefers morning meetings before 11 AM",
                memoryType: .preference,
                category: .work,
                confidence: 0.95,
                source: .inferred
            ),
            Memory(
                userId: userId,
                content: "Allergic to shellfish - avoid seafood restaurants",
                memoryType: .fact,
                category: .health,
                confidence: 1.0,
                source: .explicit
            ),
            Memory(
                userId: userId,
                content: "Working on Jarvis AI Assistant project",
                memoryType: .context,
                category: .work,
                confidence: 1.0,
                source: .inferred
            ),
            Memory(
                userId: userId,
                content: "Goes to gym on Monday, Wednesday, Friday evenings",
                memoryType: .routine,
                category: .health,
                confidence: 0.9,
                source: .inferred
            ),
            Memory(
                userId: userId,
                content: "Mom's phone number: (555) 123-4567",
                memoryType: .relationship,
                category: .personal,
                confidence: 1.0,
                source: .explicit
            ),
            Memory(
                userId: userId,
                content: "Prefers dark mode in all applications",
                memoryType: .preference,
                category: .general,
                confidence: 1.0,
                source: .explicit
            ),
            Memory(
                userId: userId,
                content: "Coffee order: Oat milk latte, no sugar",
                memoryType: .preference,
                category: .personal,
                confidence: 1.0,
                source: .explicit
            ),
            Memory(
                userId: userId,
                content: "Manager is Sarah Chen - weekly 1:1 on Tuesdays",
                memoryType: .relationship,
                category: .work,
                confidence: 1.0,
                source: .inferred
            ),
            Memory(
                userId: userId,
                content: "Birthday is March 15th",
                memoryType: .fact,
                category: .personal,
                confidence: 1.0,
                source: .explicit
            ),
            Memory(
                userId: userId,
                content: "Vegetarian diet preference",
                memoryType: .preference,
                category: .health,
                confidence: 0.85,
                source: .inferred
            )
        ]
    }

    // MARK: - Task/Item Sample Data

    public func generateSampleItems(userId: UUID) -> [Item] {
        let now = Date()
        let calendar = Foundation.Calendar.current

        return [
            Item(
                userId: userId,
                title: "Review PR #127",
                content: "Code review for voice commands feature",
                priority: .high,
                dueDate: now.addingTimeInterval(3600),
                tags: ["work", "code-review"]
            ),
            Item(
                userId: userId,
                title: "Prepare Q3 presentation slides",
                content: "Final review before client meeting tomorrow",
                priority: .urgent,
                dueDate: calendar.date(byAdding: .day, value: 1, to: now),
                tags: ["work", "presentation"]
            ),
            Item(
                userId: userId,
                title: "Book flight to NYC",
                content: "Conference trip next month - need to book before prices go up",
                priority: .medium,
                dueDate: calendar.date(byAdding: .day, value: 3, to: now),
                tags: ["travel", "personal"]
            ),
            Item(
                userId: userId,
                title: "Call Mom",
                content: "Confirm Sunday dinner plans",
                priority: .medium,
                dueDate: calendar.date(byAdding: .day, value: 2, to: now),
                tags: ["personal", "family"]
            ),
            Item(
                userId: userId,
                title: "Renew gym membership",
                content: "Expires next week - check if they have annual discount",
                priority: .low,
                dueDate: calendar.date(byAdding: .day, value: 5, to: now),
                tags: ["personal", "health"]
            ),
            Item(
                userId: userId,
                title: "Update project documentation",
                content: "Add API docs for new endpoints",
                priority: .medium,
                tags: ["work", "documentation"]
            ),
            Item(
                userId: userId,
                title: "Schedule team offsite",
                content: "Find venue and send calendar invites for Q1 planning",
                priority: .medium,
                dueDate: calendar.date(byAdding: .day, value: 7, to: now),
                tags: ["work", "planning"]
            ),
            Item(
                userId: userId,
                title: "Buy hiking boots",
                content: "Need new boots before Saturday hike with Alex",
                priority: .high,
                dueDate: calendar.date(byAdding: .day, value: 4, to: now),
                tags: ["personal", "shopping"]
            )
        ]
    }

    // MARK: - Activity Log Sample Data

    public func generateSampleActivities() -> [ActivityEntry] {
        let now = Date()

        return [
            ActivityEntry(
                id: UUID(),
                timestamp: now.addingTimeInterval(-300),
                type: .emailDrafted,
                title: "Draft reply to Sarah Chen",
                description: "AI drafted response to urgent presentation email",
                status: .pendingApproval
            ),
            ActivityEntry(
                id: UUID(),
                timestamp: now.addingTimeInterval(-1800),
                type: .calendarEventCreated,
                title: "Scheduled follow-up meeting",
                description: "Added 'Client Follow-up' to calendar for Friday",
                status: .completed
            ),
            ActivityEntry(
                id: UUID(),
                timestamp: now.addingTimeInterval(-3600),
                type: .reminderSet,
                title: "Reminder: Call Mom",
                description: "Set reminder for tomorrow at 6 PM",
                status: .completed
            ),
            ActivityEntry(
                id: UUID(),
                timestamp: now.addingTimeInterval(-7200),
                type: .memoryLearned,
                title: "Learned preference",
                description: "Noted that you prefer morning meetings",
                status: .completed
            ),
            ActivityEntry(
                id: UUID(),
                timestamp: now.addingTimeInterval(-14400),
                type: .taskCompleted,
                title: "Marked task complete",
                description: "Completed: Submit expense report",
                status: .completed
            )
        ]
    }
}

// MARK: - Supporting Types

public struct ActivityEntry: Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let type: ActivityType
    public let title: String
    public let description: String
    public let status: ActivityStatus

    public enum ActivityType: String {
        case emailDrafted = "email_drafted"
        case emailSent = "email_sent"
        case calendarEventCreated = "calendar_event_created"
        case reminderSet = "reminder_set"
        case memoryLearned = "memory_learned"
        case taskCompleted = "task_completed"
        case taskCreated = "task_created"
    }

    public enum ActivityStatus: String {
        case completed = "completed"
        case pendingApproval = "pending_approval"
        case failed = "failed"
    }
}
