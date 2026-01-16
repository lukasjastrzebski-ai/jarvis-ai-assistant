import Foundation

/// App secrets and API keys - MOCK VALUES FOR TESTING
/// Replace with real values before production deployment
public enum Secrets {
    // MARK: - API Endpoints

    #if DEBUG
    public static let apiBaseURL = "http://localhost:8787"
    #else
    public static let apiBaseURL = "https://jarvis-api-mock.test"
    #endif

    // MARK: - Google OAuth (Mock)

    public static let googleClientID = "mock-client-id.apps.googleusercontent.com"
    public static let googleReversedClientID = "com.googleusercontent.apps.mock-client-id"

    // MARK: - OpenAI (Mock)

    public static let openAIAPIKey = "sk-mock-openai-api-key"

    // MARK: - Feature Flags

    public static let isVoiceEnabled = true
    public static let isGmailSyncEnabled = true
    public static let isCalendarSyncEnabled = true
    public static let isAIDraftingEnabled = true

    // MARK: - Mock Mode

    /// When true, all external services use mock implementations
    public static let useMockServices = true
}

/// Environment configuration
public enum AppEnvironment: String {
    case development
    case staging
    case production

    public static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    public var apiBaseURL: String {
        switch self {
        case .development:
            return "http://localhost:8787"
        case .staging:
            return "https://jarvis-api-staging.test"
        case .production:
            return "https://jarvis-api.test"
        }
    }
}
