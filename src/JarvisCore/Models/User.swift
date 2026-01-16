import Foundation

/// Represents a user in the Jarvis system
public struct User: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var email: String
    public var displayName: String?
    public var avatarURL: URL?
    public var createdAt: Date
    public var updatedAt: Date
    public var lastSyncedAt: Date?

    /// User preferences stored as JSON
    public var preferences: UserPreferences

    public init(
        id: UUID = UUID(),
        email: String,
        displayName: String? = nil,
        avatarURL: URL? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastSyncedAt: Date? = nil,
        preferences: UserPreferences = UserPreferences()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSyncedAt = lastSyncedAt
        self.preferences = preferences
    }
}

/// User preferences configuration
public struct UserPreferences: Codable, Equatable, Sendable {
    public var notificationsEnabled: Bool
    public var dailyDigestTime: DateComponents?
    public var theme: Theme
    public var defaultCalendarId: String?

    public init(
        notificationsEnabled: Bool = true,
        dailyDigestTime: DateComponents? = nil,
        theme: Theme = .system,
        defaultCalendarId: String? = nil
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.dailyDigestTime = dailyDigestTime
        self.theme = theme
        self.defaultCalendarId = defaultCalendarId
    }

    public enum Theme: String, Codable, Sendable {
        case light
        case dark
        case system
    }
}
