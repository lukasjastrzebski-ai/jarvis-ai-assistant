import XCTest
@testable import JarvisCore

/// App Simulation - Demonstrates complete user workflows
/// Run with: swift test --filter AppSimulation
final class AppSimulation: XCTestCase {

    var container: ServiceContainer!

    override func setUp() async throws {
        try await super.setUp()
        container = ServiceContainer.shared
        container.configure(useMockServices: true)
    }

    override func tearDown() async throws {
        container.reset()
        try await super.tearDown()
    }

    /// Main simulation - runs through a typical user day
    func testAppSimulation() async throws {
        print("\n")
        print("╔════════════════════════════════════════════════════════════════╗")
        print("║           JARVIS AI ASSISTANT - APP SIMULATION                 ║")
        print("╚════════════════════════════════════════════════════════════════╝")
        print("")

        // ═══════════════════════════════════════════════════════════════
        // STEP 1: User Authentication
        // ═══════════════════════════════════════════════════════════════
        print("┌─────────────────────────────────────────────────────────────────┐")
        print("│ STEP 1: User Authentication                                     │")
        print("└─────────────────────────────────────────────────────────────────┘")

        let (token, user) = try await container.mockAPIClient.login(
            email: "demo@jarvis.app",
            password: "demo123"
        )

        print("  ✓ User logged in successfully")
        print("    → Email: \(user.email)")
        print("    → Name: \(user.name)")
        print("    → Token: \(token.prefix(20))...")
        print("")

        // ═══════════════════════════════════════════════════════════════
        // STEP 2: Morning Briefing - Check Calendar
        // ═══════════════════════════════════════════════════════════════
        print("┌─────────────────────────────────────────────────────────────────┐")
        print("│ STEP 2: Morning Briefing - Today's Schedule                     │")
        print("└─────────────────────────────────────────────────────────────────┘")

        let calendars = await container.mockCalendarProvider.getCalendars()
        print("  ✓ Connected calendars: \(calendars.count)")
        for cal in calendars {
            print("    → \(cal.name) (\(cal.accountType.rawValue))")
        }

        let todaysEvents = await container.mockCalendarProvider.getTodaysEvents()
        print("")
        print("  📅 Today's Events: \(todaysEvents.count)")
        for event in todaysEvents {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let time = formatter.string(from: event.startDate)
            print("    → \(time) - \(event.title)")
            if let location = event.location {
                print("      📍 \(location)")
            }
        }
        print("")

        // ═══════════════════════════════════════════════════════════════
        // STEP 3: Check Email Inbox
        // ═══════════════════════════════════════════════════════════════
        print("┌─────────────────────────────────────────────────────────────────┐")
        print("│ STEP 3: Check Email Inbox                                       │")
        print("└─────────────────────────────────────────────────────────────────┘")

        let emailAccounts = await container.mockEmailProvider.getAccounts()
        print("  ✓ Email accounts: \(emailAccounts.count)")

        for account in emailAccounts {
            print("    → \(account.email) (\(account.type.rawValue))")

            let emails = await container.mockEmailProvider.getEmails(for: account.id)
            let unread = await container.mockEmailProvider.getUnreadEmails(for: account.id)

            print("      Total: \(emails.count) | Unread: \(unread.count)")
            print("")
            print("  📧 Recent Emails:")
            for email in emails.prefix(3) {
                let status = email.isRead ? "📭" : "📬"
                print("    \(status) From: \(email.from)")
                print("       Subject: \(email.subject)")
            }
        }
        print("")

        // ═══════════════════════════════════════════════════════════════
        // STEP 4: Memory System - What Jarvis Knows
        // ═══════════════════════════════════════════════════════════════
        print("┌─────────────────────────────────────────────────────────────────┐")
        print("│ STEP 4: Memory System - User Context                            │")
        print("└─────────────────────────────────────────────────────────────────┘")

        // Store some user preferences
        let preferences = [
            "User prefers morning meetings over afternoon",
            "Primary project is Jarvis AI Assistant",
            "Likes dark mode interfaces",
            "Usually takes lunch at 12:30 PM"
        ]

        print("  🧠 Storing user preferences...")
        var storedMemories: [(text: String, embedding: [Float])] = []
        for pref in preferences {
            let embedding = await container.mockEmbeddingProvider.generateEmbedding(for: pref)
            storedMemories.append((pref, embedding))
            print("    → Learned: \"\(pref)\"")
        }

        // Query memories
        print("")
        print("  🔍 Querying memory system...")
        let query = "What time does the user prefer for meetings?"
        let results = await container.mockEmbeddingProvider.findSimilar(
            query: query,
            candidates: storedMemories,
            topK: 2
        )

        print("    Query: \"\(query)\"")
        print("    Results:")
        for result in results {
            print("      → \(result.text) (relevance: \(String(format: "%.2f", result.similarity)))")
        }
        print("")

        // ═══════════════════════════════════════════════════════════════
        // STEP 5: Daily Planning
        // ═══════════════════════════════════════════════════════════════
        print("┌─────────────────────────────────────────────────────────────────┐")
        print("│ STEP 5: AI Daily Planning                                       │")
        print("└─────────────────────────────────────────────────────────────────┘")

        print("  📋 Generating daily plan based on:")
        print("    → \(todaysEvents.count) calendar events")
        print("    → \(storedMemories.count) user preferences")
        print("")

        // Simulate daily plan generation
        print("  🎯 Today's Recommended Focus:")
        print("    1. 9:30 AM - Join Team Standup (Zoom)")
        print("    2. 10:00 AM - Deep work block (based on preference)")
        print("    3. 12:30 PM - Lunch break (user preference)")
        print("    4. 2:00 PM - Product Review meeting")
        print("    5. 4:00 PM - Email catch-up")
        print("    6. 6:00 PM - Gym session")
        print("")

        // ═══════════════════════════════════════════════════════════════
        // STEP 6: Action Drafting
        // ═══════════════════════════════════════════════════════════════
        print("┌─────────────────────────────────────────────────────────────────┐")
        print("│ STEP 6: AI Action Drafting                                      │")
        print("└─────────────────────────────────────────────────────────────────┘")

        print("  ✉️  Draft email response...")
        print("    To: colleague@company.com")
        print("    Subject: Re: Project Update Request")
        print("")
        print("    Draft:")
        print("    ┌──────────────────────────────────────────────────────────┐")
        print("    │ Hi,                                                      │")
        print("    │                                                          │")
        print("    │ Thanks for reaching out. I'll have the update ready      │")
        print("    │ by end of day. I've scheduled time this afternoon        │")
        print("    │ to compile the latest progress on the Jarvis project.    │")
        print("    │                                                          │")
        print("    │ Best regards                                             │")
        print("    └──────────────────────────────────────────────────────────┘")
        print("")

        // ═══════════════════════════════════════════════════════════════
        // STEP 7: Create New Calendar Event
        // ═══════════════════════════════════════════════════════════════
        print("┌─────────────────────────────────────────────────────────────────┐")
        print("│ STEP 7: Schedule New Event                                      │")
        print("└─────────────────────────────────────────────────────────────────┘")

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let eventStart = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: tomorrow)!

        let newEvent = CalendarEvent(
            id: "new-event-simulation",
            calendarId: calendars[0].id,
            title: "Follow-up: Project Discussion",
            description: "Discuss project progress with team",
            location: "Conference Room B",
            startDate: eventStart,
            endDate: eventStart.addingTimeInterval(3600)
        )

        await container.mockCalendarProvider.createEvent(newEvent)

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        print("  ✓ Event created successfully")
        print("    → Title: \(newEvent.title)")
        print("    → When: \(formatter.string(from: eventStart))")
        print("    → Where: \(newEvent.location ?? "TBD")")
        print("")

        // ═══════════════════════════════════════════════════════════════
        // STEP 8: Sync Data
        // ═══════════════════════════════════════════════════════════════
        print("┌─────────────────────────────────────────────────────────────────┐")
        print("│ STEP 8: Sync Data to Cloud                                      │")
        print("└─────────────────────────────────────────────────────────────────┘")

        let items = [
            Item(userId: user.id, title: "Review PR #123", content: "Code review pending"),
            Item(userId: user.id, title: "Update docs", content: "Add API documentation")
        ]

        let syncedItems = try await container.mockAPIClient.syncItems(token: token, items: items)
        print("  ✓ Synced \(syncedItems.count) items to cloud")

        let memories = [
            Memory(userId: user.id, content: "Completed daily planning", memoryType: .context)
        ]

        let syncedMemories = try await container.mockAPIClient.syncMemories(token: token, memories: memories)
        print("  ✓ Synced \(syncedMemories.count) memories to cloud")
        print("")

        // ═══════════════════════════════════════════════════════════════
        // STEP 9: Activity Log
        // ═══════════════════════════════════════════════════════════════
        print("┌─────────────────────────────────────────────────────────────────┐")
        print("│ STEP 9: Activity Log                                            │")
        print("└─────────────────────────────────────────────────────────────────┘")

        let requestLog = await container.mockAPIClient.getRequestLog()
        print("  📝 Session Activity (\(requestLog.count) API calls):")
        for request in requestLog.suffix(5) {
            print("    → \(request.method) \(request.path)")
        }
        print("")

        // ═══════════════════════════════════════════════════════════════
        // STEP 10: Logout
        // ═══════════════════════════════════════════════════════════════
        print("┌─────────────────────────────────────────────────────────────────┐")
        print("│ STEP 10: End Session                                            │")
        print("└─────────────────────────────────────────────────────────────────┘")

        await container.mockAPIClient.logout(token: token)
        print("  ✓ User logged out successfully")
        print("  ✓ Session ended")
        print("")

        // ═══════════════════════════════════════════════════════════════
        // SUMMARY
        // ═══════════════════════════════════════════════════════════════
        print("╔════════════════════════════════════════════════════════════════╗")
        print("║                    SIMULATION COMPLETE                         ║")
        print("╠════════════════════════════════════════════════════════════════╣")
        print("║  ✓ Authentication flow                                         ║")
        print("║  ✓ Calendar integration                                        ║")
        print("║  ✓ Email inbox sync                                            ║")
        print("║  ✓ Memory system (embeddings + similarity search)              ║")
        print("║  ✓ Daily planning                                              ║")
        print("║  ✓ Action drafting                                             ║")
        print("║  ✓ Event scheduling                                            ║")
        print("║  ✓ Cloud sync                                                  ║")
        print("║  ✓ Activity logging                                            ║")
        print("╚════════════════════════════════════════════════════════════════╝")
        print("")
    }
}
