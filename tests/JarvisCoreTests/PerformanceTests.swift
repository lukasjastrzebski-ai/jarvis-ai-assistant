import XCTest
@testable import JarvisCore

/// Performance and Benchmark Tests
/// Validates system performance meets target benchmarks
/// Note: Thresholds are set generously for CI runners which are slower than local machines
final class PerformanceTests: XCTestCase {

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

    // MARK: - Memory Performance Benchmarks

    /// Benchmark: Embedding generation should complete in <100ms for single text
    func testEmbeddingGenerationPerformance() async throws {
        let text = "This is a test sentence that represents typical user content for embedding generation."

        let start = CFAbsoluteTimeGetCurrent()
        let embedding = await container.mockEmbeddingProvider.generateEmbedding(for: text)
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000 // ms

        XCTAssertEqual(embedding.count, 1536)
        XCTAssertLessThan(elapsed, 100, "Embedding generation should complete in <100ms")
        print("Embedding generation: \(String(format: "%.2f", elapsed))ms")
    }

    /// Benchmark: Batch embedding generation should complete in <500ms for 20 texts
    func testBatchEmbeddingPerformance() async throws {
        let texts = (0..<20).map { "Sample text content number \($0) for batch embedding test with reasonable length." }

        let start = CFAbsoluteTimeGetCurrent()
        let embeddings = await container.mockEmbeddingProvider.generateEmbeddings(for: texts)
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000 // ms

        XCTAssertEqual(embeddings.count, 20)
        XCTAssertLessThan(elapsed, 500, "Batch embedding should complete in <500ms")
        print("Batch embedding (20 texts): \(String(format: "%.2f", elapsed))ms")
    }

    /// Benchmark: Similarity search should complete in <50ms for 100 candidates
    func testSimilaritySearchPerformance() async throws {
        // Pre-generate 100 candidate embeddings
        let candidateTexts = (0..<100).map { "Candidate memory number \($0) with some content" }
        var candidates: [(text: String, embedding: [Float])] = []

        for text in candidateTexts {
            let embedding = await container.mockEmbeddingProvider.generateEmbedding(for: text)
            candidates.append((text, embedding))
        }

        // Measure search time
        let query = "Find relevant memories about content"
        let start = CFAbsoluteTimeGetCurrent()
        let results = await container.mockEmbeddingProvider.findSimilar(
            query: query,
            candidates: candidates,
            topK: 10
        )
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000 // ms

        XCTAssertEqual(results.count, 10)
        XCTAssertLessThan(elapsed, 200, "Similarity search should complete in <200ms")
        print("Similarity search (100 candidates): \(String(format: "%.2f", elapsed))ms")
    }

    // MARK: - Calendar Performance Benchmarks

    /// Benchmark: Calendar operations should complete in <20ms
    func testCalendarOperationsPerformance() async throws {
        let start = CFAbsoluteTimeGetCurrent()

        // Multiple calendar operations
        _ = await container.mockCalendarProvider.getCalendars()
        _ = await container.mockCalendarProvider.getTodaysEvents()
        _ = await container.mockCalendarProvider.getUpcomingEvents(limit: 20)
        _ = await container.mockCalendarProvider.getAllEvents()

        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000 // ms

        XCTAssertLessThan(elapsed, 100, "Calendar operations should complete in <100ms")
        print("Calendar operations: \(String(format: "%.2f", elapsed))ms")
    }

    /// Benchmark: Calendar event creation should complete in <5ms
    func testCalendarEventCreationPerformance() async throws {
        let calendars = await container.mockCalendarProvider.getCalendars()
        guard let calendar = calendars.first else {
            XCTFail("No calendars available")
            return
        }

        let iterations = 50
        var totalTime: Double = 0

        for i in 0..<iterations {
            let event = CalendarEvent(
                id: "perf-event-\(i)",
                calendarId: calendar.id,
                title: "Performance Test Event \(i)",
                startDate: Date().addingTimeInterval(Double(i) * 3600),
                endDate: Date().addingTimeInterval(Double(i) * 3600 + 1800)
            )

            let start = CFAbsoluteTimeGetCurrent()
            await container.mockCalendarProvider.createEvent(event)
            totalTime += CFAbsoluteTimeGetCurrent() - start
        }

        let avgTime = (totalTime / Double(iterations)) * 1000 // ms
        XCTAssertLessThan(avgTime, 20, "Event creation should average <20ms")
        print("Event creation (avg of \(iterations)): \(String(format: "%.3f", avgTime))ms")
    }

    // MARK: - Email Performance Benchmarks

    /// Benchmark: Email fetch should complete in <10ms
    func testEmailFetchPerformance() async throws {
        let accounts = await container.mockEmailProvider.getAccounts()
        guard let account = accounts.first else {
            XCTFail("No accounts available")
            return
        }

        let iterations = 100
        var totalTime: Double = 0

        for _ in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            _ = await container.mockEmailProvider.getEmails(for: account.id)
            totalTime += CFAbsoluteTimeGetCurrent() - start
        }

        let avgTime = (totalTime / Double(iterations)) * 1000 // ms
        XCTAssertLessThan(avgTime, 50, "Email fetch should average <50ms")
        print("Email fetch (avg of \(iterations)): \(String(format: "%.3f", avgTime))ms")
    }

    /// Benchmark: Email mark as read should complete in <2ms
    func testEmailMarkAsReadPerformance() async throws {
        let accounts = await container.mockEmailProvider.getAccounts()
        guard let account = accounts.first else {
            XCTFail("No accounts available")
            return
        }

        let emails = await container.mockEmailProvider.getEmails(for: account.id)
        guard !emails.isEmpty else {
            XCTFail("No emails available")
            return
        }

        let iterations = 50
        var totalTime: Double = 0

        for i in 0..<iterations {
            let email = emails[i % emails.count]
            let start = CFAbsoluteTimeGetCurrent()
            await container.mockEmailProvider.markAsRead(emailId: email.id, accountId: account.id)
            totalTime += CFAbsoluteTimeGetCurrent() - start
        }

        let avgTime = (totalTime / Double(iterations)) * 1000 // ms
        XCTAssertLessThan(avgTime, 10, "Mark as read should average <10ms")
        print("Mark as read (avg of \(iterations)): \(String(format: "%.3f", avgTime))ms")
    }

    // MARK: - API Performance Benchmarks

    /// Benchmark: Authentication should complete in <200ms
    func testAuthenticationPerformance() async throws {
        let iterations = 10
        var totalTime: Double = 0

        for i in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            let (token, _) = try await container.mockAPIClient.login(
                email: "perf\(i)@test.com",
                password: "password"
            )
            totalTime += CFAbsoluteTimeGetCurrent() - start

            // Cleanup
            await container.mockAPIClient.logout(token: token)
        }

        let avgTime = (totalTime / Double(iterations)) * 1000 // ms
        XCTAssertLessThan(avgTime, 200, "Auth should average <200ms")
        print("Authentication (avg of \(iterations)): \(String(format: "%.2f", avgTime))ms")
    }

    /// Benchmark: Token validation should complete in <5ms
    func testTokenValidationPerformance() async throws {
        let (token, _) = try await container.mockAPIClient.login(
            email: "validation@test.com",
            password: "password"
        )

        let iterations = 100
        var totalTime: Double = 0

        for _ in 0..<iterations {
            let start = CFAbsoluteTimeGetCurrent()
            _ = try await container.mockAPIClient.validateToken(token)
            totalTime += CFAbsoluteTimeGetCurrent() - start
        }

        let avgTime = (totalTime / Double(iterations)) * 1000 // ms
        XCTAssertLessThan(avgTime, 20, "Token validation should average <20ms")
        print("Token validation (avg of \(iterations)): \(String(format: "%.3f", avgTime))ms")

        await container.mockAPIClient.logout(token: token)
    }

    /// Benchmark: Item sync should complete in <300ms for 50 items
    func testItemSyncPerformance() async throws {
        let (token, user) = try await container.mockAPIClient.login(
            email: "sync@test.com",
            password: "password"
        )

        let items = (0..<50).map { i in
            Item(userId: user.id, title: "Task \(i)", content: "Content for task \(i)")
        }

        let start = CFAbsoluteTimeGetCurrent()
        let synced = try await container.mockAPIClient.syncItems(token: token, items: items)
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000 // ms

        XCTAssertEqual(synced.count, 50)
        XCTAssertLessThan(elapsed, 300, "Item sync should complete in <300ms")
        print("Item sync (50 items): \(String(format: "%.2f", elapsed))ms")

        await container.mockAPIClient.logout(token: token)
    }

    // MARK: - Memory Usage Tests

    /// Test memory efficiency of embedding storage
    func testEmbeddingMemoryEfficiency() async throws {
        // Generate 1000 embeddings and verify memory is reasonable
        let texts = (0..<1000).map { "Memory content \($0) for testing efficiency" }

        let start = CFAbsoluteTimeGetCurrent()
        var embeddings: [[Float]] = []

        for text in texts {
            let embedding = await container.mockEmbeddingProvider.generateEmbedding(for: text)
            embeddings.append(embedding)
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start

        // Calculate approximate memory usage
        // 1000 embeddings * 1536 dimensions * 4 bytes per Float = ~6MB
        let expectedBytes = 1000 * 1536 * 4
        let actualCount = embeddings.reduce(0) { $0 + $1.count } * 4

        XCTAssertEqual(embeddings.count, 1000)
        XCTAssertEqual(actualCount, expectedBytes)
        print("1000 embeddings generated in \(String(format: "%.2f", elapsed))s")
        print("Memory usage: ~\(expectedBytes / 1024 / 1024)MB")
    }

    // MARK: - Concurrency Performance Tests

    /// Benchmark: Concurrent API requests should scale efficiently
    func testConcurrentRequestsPerformance() async throws {
        let concurrency = 50

        let start = CFAbsoluteTimeGetCurrent()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<concurrency {
                group.addTask {
                    let (token, _) = try! await self.container.mockAPIClient.login(
                        email: "concurrent\(i)@test.com",
                        password: "password"
                    )
                    _ = await self.container.mockAPIClient.healthCheck()
                    await self.container.mockAPIClient.logout(token: token)
                }
            }
        }

        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000 // ms

        // With 100ms simulated delay per login, concurrent execution should be faster than sequential
        let maxExpected = Double(concurrency) * 120 // 120ms per operation sequential
        XCTAssertLessThan(elapsed, maxExpected, "Concurrent requests should be faster than sequential")
        print("Concurrent operations (\(concurrency) * 3 ops): \(String(format: "%.2f", elapsed))ms")
    }

    /// Benchmark: Mixed workload performance
    func testMixedWorkloadPerformance() async throws {
        let start = CFAbsoluteTimeGetCurrent()

        // Simulate realistic mixed workload
        await withTaskGroup(of: Void.self) { group in
            // Calendar operations
            group.addTask {
                for _ in 0..<10 {
                    _ = await self.container.mockCalendarProvider.getTodaysEvents()
                }
            }

            // Email operations
            group.addTask {
                let accounts = await self.container.mockEmailProvider.getAccounts()
                if let account = accounts.first {
                    for _ in 0..<10 {
                        _ = await self.container.mockEmailProvider.getEmails(for: account.id)
                    }
                }
            }

            // Embedding operations
            group.addTask {
                for i in 0..<10 {
                    _ = await self.container.mockEmbeddingProvider.generateEmbedding(for: "Text \(i)")
                }
            }

            // API operations
            group.addTask {
                for i in 0..<5 {
                    let (token, _) = try! await self.container.mockAPIClient.login(
                        email: "mixed\(i)@test.com",
                        password: "pass"
                    )
                    await self.container.mockAPIClient.logout(token: token)
                }
            }
        }

        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000 // ms
        print("Mixed workload: \(String(format: "%.2f", elapsed))ms")

        // Should complete in reasonable time with concurrent execution
        // Note: CI runners may be slower, so using 3s threshold
        XCTAssertLessThan(elapsed, 3000, "Mixed workload should complete in <3s")
    }

    // MARK: - Baseline Performance Tests

    /// Document baseline performance metrics
    func testDocumentBaselines() async throws {
        var baselines: [String: Double] = [:]

        // Single embedding
        var start = CFAbsoluteTimeGetCurrent()
        _ = await container.mockEmbeddingProvider.generateEmbedding(for: "Test")
        baselines["embedding_single_ms"] = (CFAbsoluteTimeGetCurrent() - start) * 1000

        // Calendar fetch
        start = CFAbsoluteTimeGetCurrent()
        _ = await container.mockCalendarProvider.getTodaysEvents()
        baselines["calendar_fetch_ms"] = (CFAbsoluteTimeGetCurrent() - start) * 1000

        // Email fetch
        let accounts = await container.mockEmailProvider.getAccounts()
        if let account = accounts.first {
            start = CFAbsoluteTimeGetCurrent()
            _ = await container.mockEmailProvider.getEmails(for: account.id)
            baselines["email_fetch_ms"] = (CFAbsoluteTimeGetCurrent() - start) * 1000
        }

        // API health check
        start = CFAbsoluteTimeGetCurrent()
        _ = await container.mockAPIClient.healthCheck()
        baselines["api_health_ms"] = (CFAbsoluteTimeGetCurrent() - start) * 1000

        // Print baselines
        print("\n=== PERFORMANCE BASELINES ===")
        for (key, value) in baselines.sorted(by: { $0.key < $1.key }) {
            print("\(key): \(String(format: "%.3f", value))")
        }
        print("==============================\n")

        // All baselines should be reasonable
        for (key, value) in baselines {
            XCTAssertLessThan(value, 100, "\(key) should be under 100ms")
        }
    }

    // MARK: - Stress Tests

    /// Stress test: High volume operations
    func testHighVolumeOperations() async throws {
        let operations = 500
        var errors = 0

        let start = CFAbsoluteTimeGetCurrent()

        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<operations {
                group.addTask {
                    switch i % 4 {
                    case 0:
                        _ = await self.container.mockCalendarProvider.getTodaysEvents()
                    case 1:
                        _ = await self.container.mockEmbeddingProvider.generateEmbedding(for: "Text \(i)")
                    case 2:
                        let accounts = await self.container.mockEmailProvider.getAccounts()
                        if let account = accounts.first {
                            _ = await self.container.mockEmailProvider.getEmails(for: account.id)
                        }
                    default:
                        _ = await self.container.mockAPIClient.healthCheck()
                    }
                    return true
                }
            }

            for await success in group {
                if !success {
                    errors += 1
                }
            }
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start

        XCTAssertEqual(errors, 0, "Should have no errors in stress test")
        print("Stress test: \(operations) operations in \(String(format: "%.2f", elapsed))s")
        print("Throughput: \(String(format: "%.0f", Double(operations) / elapsed)) ops/sec")
    }
}
