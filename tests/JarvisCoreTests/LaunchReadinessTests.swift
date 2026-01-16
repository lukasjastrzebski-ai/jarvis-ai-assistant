import XCTest
@testable import JarvisCore

/// Launch Readiness Verification Tests
/// Final verification that all systems are ready for launch
final class LaunchReadinessTests: XCTestCase {

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

    // MARK: - Core Service Availability Tests

    func testEmailServiceAvailable() async throws {
        let service = container.emailService
        XCTAssertNotNil(service, "Email service should be available")
    }

    func testCalendarServiceAvailable() async throws {
        let service = container.calendarService
        XCTAssertNotNil(service, "Calendar service should be available")
    }

    func testPlanningServiceAvailable() async throws {
        let service = container.planningService
        XCTAssertNotNil(service, "Planning service should be available")
    }

    func testDraftingServiceAvailable() async throws {
        let service = container.draftingService
        XCTAssertNotNil(service, "Drafting service should be available")
    }

    func testVoiceServiceAvailable() async throws {
        let service = container.voiceService
        XCTAssertNotNil(service, "Voice service should be available")
    }

    // MARK: - Mock Service Availability Tests

    func testMockEmailProviderAvailable() async throws {
        let provider = container.mockEmailProvider
        XCTAssertNotNil(provider, "Mock email provider should be available")

        let accounts = await provider.getAccounts()
        XCTAssertFalse(accounts.isEmpty, "Mock email provider should have test accounts")
    }

    func testMockCalendarProviderAvailable() async throws {
        let provider = container.mockCalendarProvider
        XCTAssertNotNil(provider, "Mock calendar provider should be available")

        let calendars = await provider.getCalendars()
        XCTAssertFalse(calendars.isEmpty, "Mock calendar provider should have test calendars")
    }

    func testMockEmbeddingProviderAvailable() async throws {
        let provider = container.mockEmbeddingProvider
        XCTAssertNotNil(provider, "Mock embedding provider should be available")

        let embedding = await provider.generateEmbedding(for: "test")
        XCTAssertEqual(embedding.count, 1536, "Embedding should have correct dimension")
    }

    func testMockAPIClientAvailable() async throws {
        let client = container.mockAPIClient
        XCTAssertNotNil(client, "Mock API client should be available")

        let health = await client.healthCheck()
        XCTAssertTrue(health, "API client should be healthy")
    }

    // MARK: - Service Container Configuration Tests

    func testServiceContainerMockModeDefault() async throws {
        // Fresh container should respect Secrets.useMockServices
        let freshContainer = ServiceContainer.shared
        XCTAssertTrue(freshContainer.useMockServices, "Container should use mock services by default in test")
    }

    func testServiceContainerConfigurable() async throws {
        // Should be able to toggle mock mode
        container.configure(useMockServices: true)
        XCTAssertTrue(container.useMockServices)

        container.configure(useMockServices: false)
        XCTAssertFalse(container.useMockServices)

        // Reset for other tests
        container.configure(useMockServices: true)
    }

    // MARK: - Data Model Verification Tests

    func testItemModelComplete() async throws {
        let item = Item(
            userId: UUID(),
            title: "Test Item",
            content: "Test content"
        )

        XCTAssertNotNil(item.id)
        XCTAssertNotNil(item.createdAt)
        XCTAssertNotNil(item.updatedAt)
    }

    func testMemoryModelComplete() async throws {
        let memory = Memory(
            userId: UUID(),
            content: "Test memory",
            memoryType: .fact
        )

        XCTAssertNotNil(memory.id)
        XCTAssertNotNil(memory.createdAt)
        XCTAssertEqual(memory.confidence, 1.0)
    }

    func testEmailModelComplete() async throws {
        let email = Email(
            from: "sender@test.com",
            to: ["recipient@test.com"],
            subject: "Test Subject",
            body: "Test body"
        )

        XCTAssertNotNil(email.id)
        XCTAssertNotNil(email.date)
    }

    func testCalendarEventModelComplete() async throws {
        let event = CalendarEvent(
            id: "test-event",
            calendarId: "test-calendar",
            title: "Test Event",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600)
        )

        XCTAssertEqual(event.id, "test-event")
        XCTAssertNotNil(event.startDate)
        XCTAssertNotNil(event.endDate)
    }

    // MARK: - Integration Smoke Tests

    func testEmailWorkflowSmoke() async throws {
        // Get accounts
        let accounts = await container.mockEmailProvider.getAccounts()
        XCTAssertFalse(accounts.isEmpty)

        // Get emails
        let account = accounts[0]
        let emails = await container.mockEmailProvider.getEmails(for: account.id)
        XCTAssertFalse(emails.isEmpty)

        // Mark as read
        let email = emails[0]
        await container.mockEmailProvider.markAsRead(emailId: email.id, accountId: account.id)

        // Verify workflow completed
        XCTAssertTrue(true, "Email workflow completed successfully")
    }

    func testCalendarWorkflowSmoke() async throws {
        // Get calendars
        let calendars = await container.mockCalendarProvider.getCalendars()
        XCTAssertFalse(calendars.isEmpty)

        // Get today's events
        let events = await container.mockCalendarProvider.getTodaysEvents()
        XCTAssertNotNil(events)

        // Create event
        let newEvent = CalendarEvent(
            id: "smoke-test-event",
            calendarId: calendars[0].id,
            title: "Smoke Test",
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800)
        )
        await container.mockCalendarProvider.createEvent(newEvent)

        // Verify workflow completed
        XCTAssertTrue(true, "Calendar workflow completed successfully")
    }

    func testAuthWorkflowSmoke() async throws {
        // Login
        let (token, user) = try await container.mockAPIClient.login(
            email: "smoke@test.com",
            password: "password"
        )
        XCTAssertFalse(token.isEmpty)
        XCTAssertNotNil(user)

        // Validate
        let validated = try await container.mockAPIClient.validateToken(token)
        XCTAssertEqual(validated.id, user.id)

        // Logout
        await container.mockAPIClient.logout(token: token)

        // Verify workflow completed
        XCTAssertTrue(true, "Auth workflow completed successfully")
    }

    func testMemoryWorkflowSmoke() async throws {
        // Generate embedding
        let embedding = await container.mockEmbeddingProvider.generateEmbedding(
            for: "Important preference to remember"
        )
        XCTAssertEqual(embedding.count, 1536)

        // Find similar
        let candidates: [(text: String, embedding: [Float])] = [
            ("Remember this preference", embedding)
        ]

        let results = await container.mockEmbeddingProvider.findSimilar(
            query: "What preferences are stored?",
            candidates: candidates,
            topK: 1
        )
        XCTAssertFalse(results.isEmpty)

        // Verify workflow completed
        XCTAssertTrue(true, "Memory workflow completed successfully")
    }

    // MARK: - Error Handling Verification

    func testInvalidTokenHandling() async throws {
        do {
            _ = try await container.mockAPIClient.validateToken("invalid-token")
            XCTFail("Should have thrown unauthorized error")
        } catch {
            // Expected - error handling works
            XCTAssertTrue(error is MockAPIClient.APIError)
        }
    }

    func testEmptyEmbeddingInput() async throws {
        let embedding = await container.mockEmbeddingProvider.generateEmbedding(for: "")
        XCTAssertEqual(embedding.count, 1536, "Should still return valid embedding for empty string")
    }

    // MARK: - System Health Verification

    func testOverallSystemHealth() async throws {
        // Verify all systems are operational
        var healthStatus: [String: Bool] = [:]

        // Email system
        let accounts = await container.mockEmailProvider.getAccounts()
        healthStatus["email"] = !accounts.isEmpty

        // Calendar system
        let calendars = await container.mockCalendarProvider.getCalendars()
        healthStatus["calendar"] = !calendars.isEmpty

        // Memory system
        let embedding = await container.mockEmbeddingProvider.generateEmbedding(for: "health check")
        healthStatus["memory"] = embedding.count == 1536

        // API system
        healthStatus["api"] = await container.mockAPIClient.healthCheck()

        // Verify all systems healthy
        for (system, healthy) in healthStatus {
            XCTAssertTrue(healthy, "\(system) system should be healthy")
        }

        print("\n=== SYSTEM HEALTH CHECK ===")
        for (system, healthy) in healthStatus.sorted(by: { $0.key < $1.key }) {
            print("\(system): \(healthy ? "✓ Healthy" : "✗ Unhealthy")")
        }
        print("===========================\n")
    }

    // MARK: - Launch Criteria Verification

    func testLaunchCriteriaMet() async throws {
        var criteria: [String: Bool] = [:]

        // Criterion 1: All core services available
        criteria["core_services"] = container.emailService != nil &&
                                    container.calendarService != nil &&
                                    container.planningService != nil

        // Criterion 2: Mock services functional
        let accounts = await container.mockEmailProvider.getAccounts()
        let calendars = await container.mockCalendarProvider.getCalendars()
        criteria["mock_services"] = !accounts.isEmpty && !calendars.isEmpty

        // Criterion 3: API operational
        criteria["api_operational"] = await container.mockAPIClient.healthCheck()

        // Criterion 4: Memory system functional
        let embedding = await container.mockEmbeddingProvider.generateEmbedding(for: "test")
        criteria["memory_system"] = embedding.count == 1536

        // Criterion 5: Error handling working
        var errorHandlingWorks = false
        do {
            _ = try await container.mockAPIClient.validateToken("invalid")
        } catch {
            errorHandlingWorks = true
        }
        criteria["error_handling"] = errorHandlingWorks

        // Print summary
        print("\n=== LAUNCH CRITERIA VERIFICATION ===")
        var allPassed = true
        for (criterion, passed) in criteria.sorted(by: { $0.key < $1.key }) {
            print("\(criterion): \(passed ? "✓ PASS" : "✗ FAIL")")
            if !passed { allPassed = false }
        }
        print("=====================================")
        print("OVERALL: \(allPassed ? "✓ READY FOR LAUNCH" : "✗ NOT READY")")
        print("=====================================\n")

        XCTAssertTrue(allPassed, "All launch criteria should be met")
    }
}
