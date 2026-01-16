import Foundation

/// Mock API client for integration testing without real backend
public actor MockAPIClient {
    private var mockUsers: [UUID: MockUser] = [:]
    private var mockTokens: [String: UUID] = [:]
    private var requestLog: [APIRequest] = []

    public struct MockUser: Codable {
        let id: UUID
        let email: String
        let name: String
        let createdAt: Date
    }

    public struct APIRequest {
        let method: String
        let path: String
        let timestamp: Date
        let userId: UUID?
    }

    public enum APIError: Error, LocalizedError {
        case unauthorized
        case notFound
        case badRequest(String)
        case serverError

        public var errorDescription: String? {
            switch self {
            case .unauthorized:
                return "Unauthorized - invalid or missing token"
            case .notFound:
                return "Resource not found"
            case .badRequest(let message):
                return "Bad request: \(message)"
            case .serverError:
                return "Internal server error"
            }
        }
    }

    public init() {
        // Initialize data inline to avoid actor isolation warning
        let testUserId = UUID()
        let testUser = MockUser(
            id: testUserId,
            email: "test@example.com",
            name: "Test User",
            createdAt: Date()
        )
        mockUsers[testUserId] = testUser
        mockTokens["mock-jwt-token-12345"] = testUserId
    }

    private func seedTestData() {
        // Kept for potential future use - init now handles seeding
        // Create test user
        let testUserId = UUID()
        let testUser = MockUser(
            id: testUserId,
            email: "test@example.com",
            name: "Test User",
            createdAt: Date()
        )
        mockUsers[testUserId] = testUser

        // Create test token
        mockTokens["mock-jwt-token-12345"] = testUserId
    }

    // MARK: - Authentication

    public func login(email: String, password: String) async throws -> (token: String, user: MockUser) {
        logRequest("POST", path: "/auth/login", userId: nil)

        // Simulate delay
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // For testing, accept any email/password
        let userId = mockUsers.values.first { $0.email == email }?.id ?? UUID()

        if mockUsers[userId] == nil {
            // Create new user on first login
            let newUser = MockUser(id: userId, email: email, name: "New User", createdAt: Date())
            mockUsers[userId] = newUser
        }

        let token = "mock-jwt-token-\(UUID().uuidString.prefix(8))"
        mockTokens[token] = userId

        return (token, mockUsers[userId]!)
    }

    public func validateToken(_ token: String) async throws -> MockUser {
        logRequest("GET", path: "/auth/validate", userId: mockTokens[token])

        guard let userId = mockTokens[token],
              let user = mockUsers[userId] else {
            throw APIError.unauthorized
        }

        return user
    }

    public func logout(token: String) async {
        logRequest("POST", path: "/auth/logout", userId: mockTokens[token])
        mockTokens.removeValue(forKey: token)
    }

    // MARK: - Items API

    public func syncItems(token: String, items: [Item]) async throws -> [Item] {
        guard let userId = mockTokens[token] else {
            throw APIError.unauthorized
        }

        logRequest("POST", path: "/sync/items", userId: userId)

        // Simulate delay
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Return items with updated sync timestamps
        return items.map { item in
            var updated = item
            updated.updatedAt = Date()
            return updated
        }
    }

    // MARK: - Memories API

    public func syncMemories(token: String, memories: [Memory]) async throws -> [Memory] {
        guard let userId = mockTokens[token] else {
            throw APIError.unauthorized
        }

        logRequest("POST", path: "/sync/memories", userId: userId)

        try await Task.sleep(nanoseconds: 150_000_000) // 150ms

        return memories.map { memory in
            var updated = memory
            updated.updatedAt = Date()
            return updated
        }
    }

    // MARK: - Health Check

    public func healthCheck() async -> Bool {
        logRequest("GET", path: "/health", userId: nil)
        return true
    }

    // MARK: - Request Logging

    private func logRequest(_ method: String, path: String, userId: UUID?) {
        let request = APIRequest(
            method: method,
            path: path,
            timestamp: Date(),
            userId: userId
        )
        requestLog.append(request)

        // Keep last 100 requests
        if requestLog.count > 100 {
            requestLog.removeFirst()
        }
    }

    public func getRequestLog() -> [APIRequest] {
        return requestLog
    }

    public func clearRequestLog() {
        requestLog.removeAll()
    }
}
