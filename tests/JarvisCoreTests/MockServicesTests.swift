import XCTest
@testable import JarvisCore

final class MockServicesTests: XCTestCase {

    // MARK: - ServiceContainer Tests

    func testServiceContainerSingleton() {
        let container1 = ServiceContainer.shared
        let container2 = ServiceContainer.shared
        XCTAssertTrue(container1 === container2)
    }

    func testServiceContainerUseMockServicesDefault() {
        let container = ServiceContainer.shared
        XCTAssertEqual(container.useMockServices, Secrets.useMockServices)
    }

    func testServiceContainerConfigure() {
        let container = ServiceContainer.shared
        container.configure(useMockServices: true)
        XCTAssertTrue(container.useMockServices)

        container.configure(useMockServices: false)
        XCTAssertFalse(container.useMockServices)

        // Reset to default
        container.configure(useMockServices: Secrets.useMockServices)
    }

    func testServiceContainerReset() {
        let container = ServiceContainer.shared
        // Access services to initialize them
        _ = container.emailService
        _ = container.calendarService
        _ = container.planningService
        _ = container.draftingService
        _ = container.voiceService
        _ = container.mockEmailProvider
        _ = container.mockCalendarProvider
        _ = container.mockEmbeddingProvider
        _ = container.mockAPIClient

        // Reset should not crash
        container.reset()
    }

    // MARK: - MockEmailProvider Tests

    func testMockEmailProviderInit() async {
        let provider = MockEmailProvider()
        let accounts = await provider.getAccounts()
        XCTAssertFalse(accounts.isEmpty)
    }

    func testMockEmailProviderGetAccounts() async {
        let provider = MockEmailProvider()
        let accounts = await provider.getAccounts()

        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(accounts[0].email, "user@jarvis.app")
        XCTAssertEqual(accounts[0].displayName, "Jarvis User")
        XCTAssertTrue(accounts[0].isConnected)
    }

    func testMockEmailProviderGetEmails() async {
        let provider = MockEmailProvider()
        let accounts = await provider.getAccounts()
        guard let account = accounts.first else {
            XCTFail("No test account found")
            return
        }

        let emails = await provider.getEmails(for: account.id)
        XCTAssertEqual(emails.count, 10) // SampleDataGenerator provides 10 emails
    }

    func testMockEmailProviderGetUnreadEmails() async {
        let provider = MockEmailProvider()
        let accounts = await provider.getAccounts()
        guard let account = accounts.first else {
            XCTFail("No test account found")
            return
        }

        let unreadEmails = await provider.getUnreadEmails(for: account.id)
        XCTAssertEqual(unreadEmails.count, 4) // SampleDataGenerator provides 4 unread emails
        XCTAssertTrue(unreadEmails.allSatisfy { !$0.isRead })
    }

    func testMockEmailProviderMarkAsRead() async {
        let provider = MockEmailProvider()
        let accounts = await provider.getAccounts()
        guard let account = accounts.first else {
            XCTFail("No test account found")
            return
        }

        let emails = await provider.getEmails(for: account.id)
        let unreadEmail = emails.first { !$0.isRead }!

        await provider.markAsRead(emailId: unreadEmail.id, accountId: account.id)

        let updatedEmails = await provider.getEmails(for: account.id)
        let markedEmail = updatedEmails.first { $0.id == unreadEmail.id }!
        XCTAssertTrue(markedEmail.isRead)
    }

    func testMockEmailProviderSendEmail() async {
        let provider = MockEmailProvider()
        let accounts = await provider.getAccounts()
        guard let account = accounts.first else {
            XCTFail("No test account found")
            return
        }

        let initialCount = await provider.getEmails(for: account.id).count

        let newEmail = Email(
            from: "test@example.com",
            to: ["recipient@example.com"],
            subject: "Test Email",
            body: "This is a test email",
            date: Date()
        )

        await provider.sendEmail(newEmail, from: account.id)

        let updatedCount = await provider.getEmails(for: account.id).count
        XCTAssertEqual(updatedCount, initialCount + 1)
    }

    func testMockEmailProviderAddMockEmail() async {
        let provider = MockEmailProvider()
        let accounts = await provider.getAccounts()
        guard let account = accounts.first else {
            XCTFail("No test account found")
            return
        }

        let initialCount = await provider.getEmails(for: account.id).count

        let newEmail = Email(
            from: "sender@example.com",
            to: ["test@example.com"],
            subject: "New Mock Email",
            body: "Test content",
            date: Date()
        )

        await provider.addMockEmail(newEmail, to: account.id)

        let updatedCount = await provider.getEmails(for: account.id).count
        XCTAssertEqual(updatedCount, initialCount + 1)
    }

    // MARK: - MockCalendarProvider Tests

    func testMockCalendarProviderInit() async {
        let provider = MockCalendarProvider()
        let calendars = await provider.getCalendars()
        XCTAssertFalse(calendars.isEmpty)
    }

    func testMockCalendarProviderGetCalendars() async {
        let provider = MockCalendarProvider()
        let calendars = await provider.getCalendars()

        XCTAssertEqual(calendars.count, 2)
        XCTAssertTrue(calendars.contains { $0.name == "Work" })
        XCTAssertTrue(calendars.contains { $0.name == "Personal" })
    }

    func testMockCalendarProviderGetEvents() async {
        let provider = MockCalendarProvider()
        let workEvents = await provider.getEvents(for: "work-calendar")

        XCTAssertFalse(workEvents.isEmpty)
        XCTAssertTrue(workEvents.allSatisfy { $0.calendarId == "work-calendar" })
    }

    func testMockCalendarProviderGetAllEvents() async {
        let provider = MockCalendarProvider()
        let allEvents = await provider.getAllEvents()

        XCTAssertEqual(allEvents.count, 10) // 5 today + 2 tomorrow + 3 later this week
        // Verify sorted by start date
        for i in 0..<(allEvents.count - 1) {
            XCTAssertLessThanOrEqual(allEvents[i].startDate, allEvents[i + 1].startDate)
        }
    }

    func testMockCalendarProviderGetTodaysEvents() async {
        let provider = MockCalendarProvider()
        let todaysEvents = await provider.getTodaysEvents()

        XCTAssertEqual(todaysEvents.count, 5) // SampleDataGenerator provides 5 today's events
        let calendar = Calendar.current
        let today = Date()
        XCTAssertTrue(todaysEvents.allSatisfy { calendar.isDate($0.startDate, inSameDayAs: today) })
    }

    func testMockCalendarProviderGetUpcomingEvents() async {
        let provider = MockCalendarProvider()
        let upcomingEvents = await provider.getUpcomingEvents(limit: 5)

        XCTAssertLessThanOrEqual(upcomingEvents.count, 5)
        let now = Date()
        XCTAssertTrue(upcomingEvents.allSatisfy { $0.startDate > now })
    }

    func testMockCalendarProviderCreateEvent() async {
        let provider = MockCalendarProvider()
        let initialCount = await provider.getEvents(for: "work-calendar").count

        let newEvent = CalendarEvent(
            id: "new-event",
            calendarId: "work-calendar",
            title: "New Meeting",
            startDate: Date().addingTimeInterval(3600),
            endDate: Date().addingTimeInterval(7200)
        )

        await provider.createEvent(newEvent)

        let updatedCount = await provider.getEvents(for: "work-calendar").count
        XCTAssertEqual(updatedCount, initialCount + 1)
    }

    func testMockCalendarProviderDeleteEvent() async {
        let provider = MockCalendarProvider()
        let initialCount = await provider.getEvents(for: "work-calendar").count

        await provider.deleteEvent(id: "event-001", calendarId: "work-calendar")

        let updatedCount = await provider.getEvents(for: "work-calendar").count
        XCTAssertEqual(updatedCount, initialCount - 1)
    }

    // MARK: - MockEmbeddingProvider Tests

    func testMockEmbeddingProviderInit() async {
        let provider = MockEmbeddingProvider()
        let embedding = await provider.generateEmbedding(for: "test")
        XCTAssertEqual(embedding.count, 1536) // Default dimension
    }

    func testMockEmbeddingProviderCustomDimension() async {
        let provider = MockEmbeddingProvider(dimension: 768)
        let embedding = await provider.generateEmbedding(for: "test")
        XCTAssertEqual(embedding.count, 768)
    }

    func testMockEmbeddingProviderDeterministic() async {
        let provider = MockEmbeddingProvider()
        let text = "Hello world"

        let embedding1 = await provider.generateEmbedding(for: text)
        let embedding2 = await provider.generateEmbedding(for: text)

        XCTAssertEqual(embedding1, embedding2)
    }

    func testMockEmbeddingProviderNormalized() async {
        let provider = MockEmbeddingProvider()
        let embedding = await provider.generateEmbedding(for: "This is a test sentence")

        // Calculate magnitude
        let magnitude = sqrt(embedding.reduce(0) { $0 + $1 * $1 })

        // Should be normalized (magnitude ≈ 1)
        XCTAssertEqual(magnitude, 1.0, accuracy: 0.001)
    }

    func testMockEmbeddingProviderGenerateMultiple() async {
        let provider = MockEmbeddingProvider()
        let texts = ["Hello", "World", "Test"]

        let embeddings = await provider.generateEmbeddings(for: texts)

        XCTAssertEqual(embeddings.count, 3)
        XCTAssertTrue(embeddings.allSatisfy { $0.count == 1536 })
    }

    func testMockEmbeddingProviderCosineSimilarity() async {
        let provider = MockEmbeddingProvider()

        // Same vectors should have similarity 1
        let vec = [Float](repeating: 0.5, count: 4)
        let similarity = await provider.cosineSimilarity(vec, vec)
        XCTAssertEqual(similarity, 1.0, accuracy: 0.001)

        // Orthogonal vectors should have similarity 0
        let vec1: [Float] = [1, 0, 0, 0]
        let vec2: [Float] = [0, 1, 0, 0]
        let orthogonalSimilarity = await provider.cosineSimilarity(vec1, vec2)
        XCTAssertEqual(orthogonalSimilarity, 0.0, accuracy: 0.001)
    }

    func testMockEmbeddingProviderFindSimilar() async {
        let provider = MockEmbeddingProvider()

        let candidates: [(text: String, embedding: [Float])] = [
            ("Hello world", await provider.generateEmbedding(for: "Hello world")),
            ("Goodbye world", await provider.generateEmbedding(for: "Goodbye world")),
            ("Hello there", await provider.generateEmbedding(for: "Hello there"))
        ]

        let results = await provider.findSimilar(query: "Hello world", candidates: candidates, topK: 2)

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].text, "Hello world")
        XCTAssertEqual(results[0].similarity, 1.0, accuracy: 0.001)
    }

    // MARK: - MockAPIClient Tests

    func testMockAPIClientInit() async {
        let client = MockAPIClient()
        let isHealthy = await client.healthCheck()
        XCTAssertTrue(isHealthy)
    }

    func testMockAPIClientLogin() async throws {
        let client = MockAPIClient()
        let (token, user) = try await client.login(email: "test@example.com", password: "password")

        XCTAssertFalse(token.isEmpty)
        XCTAssertEqual(user.email, "test@example.com")
    }

    func testMockAPIClientLoginNewUser() async throws {
        let client = MockAPIClient()
        let (token, user) = try await client.login(email: "newuser@example.com", password: "password")

        XCTAssertFalse(token.isEmpty)
        XCTAssertEqual(user.email, "newuser@example.com")
        XCTAssertEqual(user.name, "New User")
    }

    func testMockAPIClientValidateToken() async throws {
        let client = MockAPIClient()
        let (token, _) = try await client.login(email: "test@example.com", password: "password")

        let validatedUser = try await client.validateToken(token)
        XCTAssertEqual(validatedUser.email, "test@example.com")
    }

    func testMockAPIClientValidateInvalidToken() async {
        let client = MockAPIClient()

        do {
            _ = try await client.validateToken("invalid-token")
            XCTFail("Should throw unauthorized error")
        } catch let error as MockAPIClient.APIError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testMockAPIClientLogout() async throws {
        let client = MockAPIClient()
        let (token, _) = try await client.login(email: "test@example.com", password: "password")

        // Validate token works before logout
        _ = try await client.validateToken(token)

        // Logout
        await client.logout(token: token)

        // Token should be invalid after logout
        do {
            _ = try await client.validateToken(token)
            XCTFail("Token should be invalid after logout")
        } catch let error as MockAPIClient.APIError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testMockAPIClientSyncItems() async throws {
        let client = MockAPIClient()
        let (token, user) = try await client.login(email: "test@example.com", password: "password")

        let items = [
            Item(userId: user.id, title: "Test Item 1", content: "Content 1"),
            Item(userId: user.id, title: "Test Item 2", content: "Content 2")
        ]

        let syncedItems = try await client.syncItems(token: token, items: items)

        XCTAssertEqual(syncedItems.count, items.count)
        XCTAssertEqual(syncedItems[0].title, items[0].title)
        XCTAssertEqual(syncedItems[1].title, items[1].title)
    }

    func testMockAPIClientSyncItemsUnauthorized() async {
        let client = MockAPIClient()

        let items = [Item(userId: UUID(), title: "Test Item", content: "Content")]

        do {
            _ = try await client.syncItems(token: "invalid-token", items: items)
            XCTFail("Should throw unauthorized error")
        } catch let error as MockAPIClient.APIError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testMockAPIClientSyncMemories() async throws {
        let client = MockAPIClient()
        let (token, user) = try await client.login(email: "test@example.com", password: "password")

        let memories = [
            Memory(userId: user.id, content: "Test memory 1", memoryType: .preference),
            Memory(userId: user.id, content: "Test memory 2", memoryType: .fact)
        ]

        let syncedMemories = try await client.syncMemories(token: token, memories: memories)

        XCTAssertEqual(syncedMemories.count, memories.count)
        XCTAssertEqual(syncedMemories[0].content, memories[0].content)
        XCTAssertEqual(syncedMemories[1].content, memories[1].content)
    }

    func testMockAPIClientRequestLog() async throws {
        let client = MockAPIClient()
        await client.clearRequestLog()

        // Make some requests
        _ = await client.healthCheck()
        _ = try await client.login(email: "test@example.com", password: "password")

        let log = await client.getRequestLog()

        XCTAssertEqual(log.count, 2)
        XCTAssertEqual(log[0].method, "GET")
        XCTAssertEqual(log[0].path, "/health")
        XCTAssertEqual(log[1].method, "POST")
        XCTAssertEqual(log[1].path, "/auth/login")
    }

    func testMockAPIClientClearRequestLog() async {
        let client = MockAPIClient()
        _ = await client.healthCheck()

        var log = await client.getRequestLog()
        XCTAssertFalse(log.isEmpty)

        await client.clearRequestLog()

        log = await client.getRequestLog()
        XCTAssertTrue(log.isEmpty)
    }

    func testMockAPIClientAPIErrorDescriptions() {
        XCTAssertNotNil(MockAPIClient.APIError.unauthorized.errorDescription)
        XCTAssertNotNil(MockAPIClient.APIError.notFound.errorDescription)
        XCTAssertNotNil(MockAPIClient.APIError.badRequest("test").errorDescription)
        XCTAssertNotNil(MockAPIClient.APIError.serverError.errorDescription)

        XCTAssertTrue(MockAPIClient.APIError.badRequest("test").errorDescription!.contains("test"))
    }

    // MARK: - ServiceContainer Integration Tests

    func testServiceContainerGetEmailsWithMocks() async throws {
        let container = ServiceContainer.shared
        container.configure(useMockServices: true)

        let accounts = await container.mockEmailProvider.getAccounts()
        guard let account = accounts.first else {
            XCTFail("No test account found")
            return
        }

        let emails = try await container.getEmails(for: account.id)
        XCTAssertFalse(emails.isEmpty)
    }

    func testServiceContainerGetTodaysEventsWithMocks() async {
        let container = ServiceContainer.shared
        container.configure(useMockServices: true)

        let events = await container.getTodaysEvents()
        XCTAssertFalse(events.isEmpty)
    }

    func testServiceContainerGenerateEmbeddingWithMocks() async {
        let container = ServiceContainer.shared
        container.configure(useMockServices: true)

        let embedding = await container.generateEmbedding(for: "Test text")
        XCTAssertEqual(embedding.count, 1536)
    }
}

// MARK: - API Error Equatable

extension MockAPIClient.APIError: Equatable {
    public static func == (lhs: MockAPIClient.APIError, rhs: MockAPIClient.APIError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized):
            return true
        case (.notFound, .notFound):
            return true
        case (.badRequest(let lhsMsg), .badRequest(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.serverError, .serverError):
            return true
        default:
            return false
        }
    }
}
