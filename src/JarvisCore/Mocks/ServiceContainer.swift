import Foundation

/// Service container for dependency injection with mock support
/// Provides centralized access to all services with ability to swap implementations
public final class ServiceContainer: @unchecked Sendable {
    public static let shared = ServiceContainer()

    // MARK: - Configuration

    /// Whether to use mock services (set from Secrets.useMockServices)
    public var useMockServices: Bool

    // MARK: - Service Instances

    // Core Services
    private var _emailService: EmailService?
    private var _calendarService: CalendarService?
    private var _planningService: DailyPlanningService?
    private var _draftingService: ActionDraftingService?
    private var _voiceService: VoiceService?

    // Mock Providers
    private var _mockEmailProvider: MockEmailProvider?
    private var _mockCalendarProvider: MockCalendarProvider?
    private var _mockEmbeddingProvider: MockEmbeddingProvider?
    private var _mockAPIClient: MockAPIClient?

    // MARK: - Initialization

    private init() {
        self.useMockServices = Secrets.useMockServices
    }

    // MARK: - Core Services

    public var emailService: EmailService {
        if _emailService == nil {
            _emailService = EmailService()
        }
        return _emailService!
    }

    public var calendarService: CalendarService {
        if _calendarService == nil {
            _calendarService = CalendarService()
        }
        return _calendarService!
    }

    public var planningService: DailyPlanningService {
        if _planningService == nil {
            _planningService = DailyPlanningService()
        }
        return _planningService!
    }

    public var draftingService: ActionDraftingService {
        if _draftingService == nil {
            _draftingService = ActionDraftingService()
        }
        return _draftingService!
    }

    public var voiceService: VoiceService {
        if _voiceService == nil {
            _voiceService = VoiceService()
        }
        return _voiceService!
    }

    // MARK: - Mock Providers

    public var mockEmailProvider: MockEmailProvider {
        if _mockEmailProvider == nil {
            _mockEmailProvider = MockEmailProvider()
        }
        return _mockEmailProvider!
    }

    public var mockCalendarProvider: MockCalendarProvider {
        if _mockCalendarProvider == nil {
            _mockCalendarProvider = MockCalendarProvider()
        }
        return _mockCalendarProvider!
    }

    public var mockEmbeddingProvider: MockEmbeddingProvider {
        if _mockEmbeddingProvider == nil {
            _mockEmbeddingProvider = MockEmbeddingProvider()
        }
        return _mockEmbeddingProvider!
    }

    public var mockAPIClient: MockAPIClient {
        if _mockAPIClient == nil {
            _mockAPIClient = MockAPIClient()
        }
        return _mockAPIClient!
    }

    // MARK: - Reset (for testing)

    public func reset() {
        _emailService = nil
        _calendarService = nil
        _planningService = nil
        _draftingService = nil
        _voiceService = nil
        _mockEmailProvider = nil
        _mockCalendarProvider = nil
        _mockEmbeddingProvider = nil
        _mockAPIClient = nil
    }

    // MARK: - Configuration

    public func configure(useMockServices: Bool) {
        self.useMockServices = useMockServices
        reset()
    }
}

// MARK: - Convenience Extensions

public extension ServiceContainer {
    /// Get emails using appropriate provider (mock or real)
    func getEmails(for accountId: UUID) async throws -> [Email] {
        if useMockServices {
            return await mockEmailProvider.getEmails(for: accountId)
        } else {
            return try await emailService.fetchEmails(accountId: accountId)
        }
    }

    /// Get calendar events using appropriate provider
    func getTodaysEvents() async -> [CalendarEvent] {
        if useMockServices {
            return await mockCalendarProvider.getTodaysEvents()
        } else {
            return await calendarService.getTodaysEvents()
        }
    }

    /// Generate embedding using appropriate provider
    func generateEmbedding(for text: String) async -> [Float] {
        if useMockServices {
            return await mockEmbeddingProvider.generateEmbedding(for: text)
        } else {
            // In production, this would call OpenAI API
            // For now, fall back to mock
            return await mockEmbeddingProvider.generateEmbedding(for: text)
        }
    }
}
