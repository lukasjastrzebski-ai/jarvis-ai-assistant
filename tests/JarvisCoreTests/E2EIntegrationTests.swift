import XCTest
@testable import JarvisCore

/// End-to-End Integration Tests using Mock Services
/// Tests complete user flows without external dependencies
final class E2EIntegrationTests: XCTestCase {

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

    // MARK: - User Authentication Flow Tests

    func testCompleteAuthenticationFlow() async throws {
        // GIVEN: A new user wanting to authenticate
        let email = "newuser@example.com"
        let password = "secure123"

        // WHEN: User logs in
        let (token, user) = try await container.mockAPIClient.login(email: email, password: password)

        // THEN: Token is issued
        XCTAssertFalse(token.isEmpty)
        XCTAssertTrue(token.hasPrefix("mock-jwt-token-"))
        XCTAssertEqual(user.email, email)

        // WHEN: Token is validated
        let validatedUser = try await container.mockAPIClient.validateToken(token)
        XCTAssertEqual(validatedUser.id, user.id)

        // WHEN: User logs out
        await container.mockAPIClient.logout(token: token)

        // THEN: Token is no longer valid
        do {
            _ = try await container.mockAPIClient.validateToken(token)
            XCTFail("Expected unauthorized error after logout")
        } catch {
            // Expected - token should be invalid
            XCTAssertTrue(error is MockAPIClient.APIError)
        }
    }

    func testMultipleUserSessions() async throws {
        // GIVEN: Two users logging in
        let (token1, user1) = try await container.mockAPIClient.login(email: "user1@test.com", password: "pass1")
        let (token2, user2) = try await container.mockAPIClient.login(email: "user2@test.com", password: "pass2")

        // THEN: Both sessions are valid and distinct
        XCTAssertNotEqual(token1, token2)
        XCTAssertNotEqual(user1.id, user2.id)

        // Validate both tokens work
        let validated1 = try await container.mockAPIClient.validateToken(token1)
        let validated2 = try await container.mockAPIClient.validateToken(token2)
        XCTAssertEqual(validated1.email, "user1@test.com")
        XCTAssertEqual(validated2.email, "user2@test.com")
    }

    // MARK: - Inbox Synchronization Flow Tests

    func testEmailInboxSyncFlow() async throws {
        // GIVEN: A connected email account
        let accounts = await container.mockEmailProvider.getAccounts()
        XCTAssertFalse(accounts.isEmpty, "Should have test email accounts")

        let account = accounts[0]

        // WHEN: Fetching emails
        let emails = await container.mockEmailProvider.getEmails(for: account.id)

        // THEN: Emails are retrieved
        XCTAssertFalse(emails.isEmpty, "Should have test emails")

        // WHEN: Checking unread emails
        let unreadBefore = await container.mockEmailProvider.getUnreadEmails(for: account.id)
        let unreadCountBefore = unreadBefore.count

        // AND: Marking first unread as read
        if let firstUnread = unreadBefore.first {
            await container.mockEmailProvider.markAsRead(emailId: firstUnread.id, accountId: account.id)

            // THEN: Unread count decreases
            let unreadAfter = await container.mockEmailProvider.getUnreadEmails(for: account.id)
            XCTAssertEqual(unreadAfter.count, unreadCountBefore - 1)
        }
    }

    func testEmailSendAndReceiveFlow() async throws {
        // GIVEN: An email account
        let accounts = await container.mockEmailProvider.getAccounts()
        let account = accounts[0]

        let initialCount = await container.mockEmailProvider.getEmails(for: account.id).count

        // WHEN: Sending a new email
        let newEmail = Email(
            id: UUID().uuidString,
            from: account.email,
            to: ["recipient@example.com"],
            subject: "Test Integration Email",
            body: "This is an integration test email.",
            date: Date(),
            isRead: true
        )

        await container.mockEmailProvider.sendEmail(newEmail, from: account.id)

        // THEN: Email count increases (sent emails are stored)
        let finalCount = await container.mockEmailProvider.getEmails(for: account.id).count
        XCTAssertEqual(finalCount, initialCount + 1)
    }

    // MARK: - Calendar Planning Flow Tests

    func testCalendarDailyPlanningFlow() async throws {
        // GIVEN: Calendar with events
        let calendars = await container.mockCalendarProvider.getCalendars()
        XCTAssertFalse(calendars.isEmpty)

        // WHEN: Getting today's schedule
        let todaysEvents = await container.mockCalendarProvider.getTodaysEvents()

        // THEN: Events are retrieved sorted by time
        if todaysEvents.count > 1 {
            for i in 0..<(todaysEvents.count - 1) {
                XCTAssertLessThanOrEqual(todaysEvents[i].startDate, todaysEvents[i + 1].startDate)
            }
        }

        // WHEN: Creating a new event
        let newEvent = CalendarEvent(
            id: "new-integration-event",
            calendarId: calendars[0].id,
            title: "Integration Test Meeting",
            description: "Testing the calendar flow",
            startDate: Date().addingTimeInterval(3600),
            endDate: Date().addingTimeInterval(7200)
        )

        await container.mockCalendarProvider.createEvent(newEvent)

        // THEN: Event is added to upcoming events
        let upcoming = await container.mockCalendarProvider.getUpcomingEvents()
        let found = upcoming.contains { $0.id == newEvent.id }
        XCTAssertTrue(found, "New event should be in upcoming events")
    }

    func testCalendarConflictDetection() async throws {
        // GIVEN: Existing events for today
        let todaysEvents = await container.mockCalendarProvider.getTodaysEvents()

        // WHEN: Checking for time conflicts
        var conflicts: [(CalendarEvent, CalendarEvent)] = []
        for i in 0..<todaysEvents.count {
            for j in (i + 1)..<todaysEvents.count {
                let event1 = todaysEvents[i]
                let event2 = todaysEvents[j]

                // Check if events overlap
                if event1.startDate < event2.endDate && event2.startDate < event1.endDate {
                    conflicts.append((event1, event2))
                }
            }
        }

        // THEN: Test infrastructure detects potential conflicts
        // (This validates the test setup, not necessarily expecting conflicts)
        print("Detected \(conflicts.count) potential conflicts in test calendar")
    }

    // MARK: - Memory System Flow Tests

    func testMemoryStorageAndRetrievalFlow() async throws {
        // GIVEN: Some memories to store
        let memories = [
            "The user prefers morning meetings over afternoon ones",
            "Important: Project deadline is next Friday",
            "User likes dark mode interfaces"
        ]

        // WHEN: Generating embeddings for memories
        var storedMemories: [(text: String, embedding: [Float])] = []
        for memory in memories {
            let embedding = await container.mockEmbeddingProvider.generateEmbedding(for: memory)
            storedMemories.append((memory, embedding))
        }

        // THEN: All embeddings are generated with correct dimension
        XCTAssertEqual(storedMemories.count, memories.count)
        for stored in storedMemories {
            XCTAssertEqual(stored.embedding.count, 1536)
        }

        // WHEN: Searching for similar memories
        let query = "What does the user prefer for meeting times?"
        let results = await container.mockEmbeddingProvider.findSimilar(
            query: query,
            candidates: storedMemories,
            topK: 2
        )

        // THEN: Relevant memories are found
        XCTAssertFalse(results.isEmpty)
        // The most relevant should be about meeting preferences
        print("Top result for '\(query)': \(results.first?.text ?? "none")")
    }

    func testMemoryEmbeddingConsistency() async throws {
        // GIVEN: The same text
        let text = "Remember this important fact about the user"

        // WHEN: Generating embeddings multiple times
        let embedding1 = await container.mockEmbeddingProvider.generateEmbedding(for: text)
        let embedding2 = await container.mockEmbeddingProvider.generateEmbedding(for: text)

        // THEN: Embeddings are deterministic (same text = same embedding)
        XCTAssertEqual(embedding1.count, embedding2.count)
        for i in 0..<embedding1.count {
            XCTAssertEqual(embedding1[i], embedding2[i], accuracy: 0.0001)
        }
    }

    // MARK: - Cross-Service Integration Tests

    func testEmailToCalendarEventFlow() async throws {
        // GIVEN: An email about a meeting
        let meetingEmail = Email(
            id: "meeting-email-001",
            from: "colleague@company.com",
            to: ["user@company.com"],
            subject: "Let's schedule a meeting",
            body: "Can we meet tomorrow at 2pm to discuss the project?",
            date: Date(),
            isRead: false
        )

        // WHEN: Processing email content for calendar event extraction
        let emailContent = "\(meetingEmail.subject) \(meetingEmail.body)"
        let embedding = await container.mockEmbeddingProvider.generateEmbedding(for: emailContent)

        // THEN: Embedding is generated for email content
        XCTAssertEqual(embedding.count, 1536)

        // WHEN: Creating a calendar event based on the email
        let calendars = await container.mockCalendarProvider.getCalendars()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let meetingStart = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: tomorrow)!

        let newEvent = CalendarEvent(
            id: "event-from-email-001",
            calendarId: calendars[0].id,
            title: "Meeting with \(meetingEmail.from)",
            description: "Re: \(meetingEmail.subject)",
            startDate: meetingStart,
            endDate: meetingStart.addingTimeInterval(3600)
        )

        await container.mockCalendarProvider.createEvent(newEvent)

        // THEN: Event is created
        let events = await container.mockCalendarProvider.getAllEvents()
        XCTAssertTrue(events.contains { $0.id == newEvent.id })
    }

    func testFullDayWorkflow() async throws {
        // GIVEN: A user starting their day
        // Step 1: Authenticate
        let (token, _) = try await container.mockAPIClient.login(
            email: "workday@test.com",
            password: "password"
        )
        XCTAssertFalse(token.isEmpty)

        // Step 2: Check today's calendar
        let todaysEvents = await container.mockCalendarProvider.getTodaysEvents()
        print("Today's schedule: \(todaysEvents.count) events")

        // Step 3: Check inbox
        let accounts = await container.mockEmailProvider.getAccounts()
        var totalUnread = 0
        for account in accounts {
            let unread = await container.mockEmailProvider.getUnreadEmails(for: account.id)
            totalUnread += unread.count
        }
        print("Unread emails: \(totalUnread)")

        // Step 4: Store a memory about the day
        let dayMemory = "Workday started with \(todaysEvents.count) events and \(totalUnread) unread emails"
        let memoryEmbedding = await container.mockEmbeddingProvider.generateEmbedding(for: dayMemory)
        XCTAssertEqual(memoryEmbedding.count, 1536)

        // Step 5: Health check on backend
        let backendHealthy = await container.mockAPIClient.healthCheck()
        XCTAssertTrue(backendHealthy)

        // Step 6: Log out
        await container.mockAPIClient.logout(token: token)

        // Verify logout
        do {
            _ = try await container.mockAPIClient.validateToken(token)
            XCTFail("Should have logged out")
        } catch {
            // Expected
        }
    }

    // MARK: - Item Sync Flow Tests

    func testItemSyncWithBackend() async throws {
        // GIVEN: A logged in user with items to sync
        let (token, user) = try await container.mockAPIClient.login(
            email: "sync@test.com",
            password: "password"
        )

        let items = [
            Item(userId: user.id, title: "Task 1", content: "Complete integration tests"),
            Item(userId: user.id, title: "Task 2", content: "Review pull requests"),
            Item(userId: user.id, title: "Task 3", content: "Update documentation")
        ]

        // WHEN: Syncing items
        let syncedItems = try await container.mockAPIClient.syncItems(token: token, items: items)

        // THEN: Items are synced with updated timestamps
        XCTAssertEqual(syncedItems.count, items.count)
        for item in syncedItems {
            XCTAssertNotNil(item.updatedAt)
        }

        // Cleanup
        await container.mockAPIClient.logout(token: token)
    }

    func testMemorySyncWithBackend() async throws {
        // GIVEN: A logged in user with memories to sync
        let (token, user) = try await container.mockAPIClient.login(
            email: "memorysync@test.com",
            password: "password"
        )

        let memories = [
            Memory(userId: user.id, content: "User preference: Dark mode", memoryType: .preference),
            Memory(userId: user.id, content: "Fact: Main project is Jarvis AI", memoryType: .fact),
            Memory(userId: user.id, content: "Context: Currently working from home", memoryType: .context)
        ]

        // WHEN: Syncing memories
        let syncedMemories = try await container.mockAPIClient.syncMemories(token: token, memories: memories)

        // THEN: Memories are synced with updated timestamps
        XCTAssertEqual(syncedMemories.count, memories.count)
        for memory in syncedMemories {
            XCTAssertNotNil(memory.updatedAt)
        }

        // Cleanup
        await container.mockAPIClient.logout(token: token)
    }

    // MARK: - Error Handling Flow Tests

    func testUnauthorizedAccessHandling() async throws {
        // GIVEN: An invalid token
        let invalidToken = "invalid-token-12345"

        // WHEN: Trying to access protected resources
        do {
            _ = try await container.mockAPIClient.validateToken(invalidToken)
            XCTFail("Should have thrown unauthorized error")
        } catch let error as MockAPIClient.APIError {
            // THEN: Unauthorized error is thrown
            XCTAssertEqual(error.localizedDescription, "Unauthorized - invalid or missing token")
        }

        // WHEN: Trying to sync items with invalid token
        do {
            let items = [Item(userId: UUID(), title: "Test", content: "Content")]
            _ = try await container.mockAPIClient.syncItems(token: invalidToken, items: items)
            XCTFail("Should have thrown unauthorized error")
        } catch let error as MockAPIClient.APIError {
            XCTAssertEqual(error.localizedDescription, "Unauthorized - invalid or missing token")
        }
    }

    func testSessionExpiration() async throws {
        // GIVEN: A valid session
        let (token, _) = try await container.mockAPIClient.login(
            email: "session@test.com",
            password: "password"
        )

        // WHEN: Session is invalidated (logout)
        await container.mockAPIClient.logout(token: token)

        // THEN: Subsequent requests fail
        do {
            _ = try await container.mockAPIClient.validateToken(token)
            XCTFail("Expired session should not validate")
        } catch {
            // Expected
        }
    }

    // MARK: - Request Logging Tests

    func testAPIRequestLogging() async throws {
        // GIVEN: A fresh API client
        await container.mockAPIClient.clearRequestLog()

        // WHEN: Making various API calls
        let (token, _) = try await container.mockAPIClient.login(email: "log@test.com", password: "pass")
        _ = await container.mockAPIClient.healthCheck()
        _ = try await container.mockAPIClient.validateToken(token)
        await container.mockAPIClient.logout(token: token)

        // THEN: All requests are logged
        let log = await container.mockAPIClient.getRequestLog()
        XCTAssertEqual(log.count, 4)

        // Verify request paths
        let paths = log.map { $0.path }
        XCTAssertTrue(paths.contains("/auth/login"))
        XCTAssertTrue(paths.contains("/health"))
        XCTAssertTrue(paths.contains("/auth/validate"))
        XCTAssertTrue(paths.contains("/auth/logout"))
    }

    // MARK: - Service Container Integration Tests

    func testServiceContainerMockModeToggle() async throws {
        // GIVEN: Container in mock mode
        XCTAssertTrue(container.useMockServices)

        // WHEN: Getting emails through container
        let accounts = await container.mockEmailProvider.getAccounts()
        guard let account = accounts.first else {
            XCTFail("No test accounts available")
            return
        }

        let emails = try await container.getEmails(for: account.id)

        // THEN: Mock emails are returned
        XCTAssertFalse(emails.isEmpty)

        // WHEN: Getting today's events through container
        let events = await container.getTodaysEvents()

        // THEN: Mock events are returned
        XCTAssertFalse(events.isEmpty)
    }

    func testServiceContainerReset() async throws {
        // GIVEN: Services have been accessed
        _ = container.emailService
        _ = container.calendarService
        _ = container.mockAPIClient

        // WHEN: Resetting the container
        container.reset()

        // THEN: Services are re-initialized on next access
        // (We can't directly test private vars, but we verify the reset doesn't crash)
        let _ = container.emailService
        let _ = container.mockAPIClient

        // Container should still be functional
        let health = await container.mockAPIClient.healthCheck()
        XCTAssertTrue(health)
    }

    // MARK: - Performance Tests

    func testBulkEmailFetchPerformance() async throws {
        let accounts = await container.mockEmailProvider.getAccounts()
        guard let account = accounts.first else { return }

        // Measure time to fetch emails multiple times
        let iterations = 100
        let start = Date()

        for _ in 0..<iterations {
            _ = await container.mockEmailProvider.getEmails(for: account.id)
        }

        let elapsed = Date().timeIntervalSince(start)
        print("Bulk email fetch: \(iterations) iterations in \(elapsed)s (\(elapsed / Double(iterations) * 1000)ms per call)")

        // Should complete in reasonable time
        XCTAssertLessThan(elapsed, 5.0, "Bulk fetch should complete in under 5 seconds")
    }

    func testBulkEmbeddingGenerationPerformance() async throws {
        let texts = (0..<50).map { "Test memory content number \($0) with some meaningful text" }

        let start = Date()
        let embeddings = await container.mockEmbeddingProvider.generateEmbeddings(for: texts)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertEqual(embeddings.count, texts.count)
        print("Bulk embedding generation: \(texts.count) embeddings in \(elapsed)s")

        // Should complete in reasonable time
        XCTAssertLessThan(elapsed, 2.0, "Bulk embedding should complete in under 2 seconds")
    }

    func testConcurrentAPIRequestsPerformance() async throws {
        await container.mockAPIClient.clearRequestLog()

        let start = Date()

        // Run multiple operations concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<20 {
                group.addTask {
                    let (token, _) = try! await self.container.mockAPIClient.login(
                        email: "concurrent\(i)@test.com",
                        password: "pass"
                    )
                    _ = await self.container.mockAPIClient.healthCheck()
                    await self.container.mockAPIClient.logout(token: token)
                }
            }
        }

        let elapsed = Date().timeIntervalSince(start)
        print("Concurrent API requests: 60 operations in \(elapsed)s")

        // Verify all requests were logged
        let log = await container.mockAPIClient.getRequestLog()
        XCTAssertEqual(log.count, 60) // 20 * 3 (login, health, logout)
    }
}
