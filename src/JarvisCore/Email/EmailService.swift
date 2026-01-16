import Foundation

/// Email message model
public struct Email: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public var from: String
    public var to: [String]
    public var cc: [String]
    public var subject: String
    public var body: String
    public var htmlBody: String?
    public var date: Date
    public var isRead: Bool
    public var isStarred: Bool
    public var labels: [String]
    public var threadId: String?
    public var attachments: [EmailAttachment]

    public init(
        id: String = UUID().uuidString,
        from: String,
        to: [String],
        cc: [String] = [],
        subject: String,
        body: String,
        htmlBody: String? = nil,
        date: Date = Date(),
        isRead: Bool = false,
        isStarred: Bool = false,
        labels: [String] = ["INBOX"],
        threadId: String? = nil,
        attachments: [EmailAttachment] = []
    ) {
        self.id = id
        self.from = from
        self.to = to
        self.cc = cc
        self.subject = subject
        self.body = body
        self.htmlBody = htmlBody
        self.date = date
        self.isRead = isRead
        self.isStarred = isStarred
        self.labels = labels
        self.threadId = threadId
        self.attachments = attachments
    }
}

/// Email attachment model
public struct EmailAttachment: Codable, Equatable, Sendable {
    public let id: String
    public let filename: String
    public let mimeType: String
    public let size: Int

    public init(id: String, filename: String, mimeType: String, size: Int) {
        self.id = id
        self.filename = filename
        self.mimeType = mimeType
        self.size = size
    }
}

/// Email account types
public enum EmailAccountType: String, Codable, Sendable {
    case gmail
    case appleMail
    case outlook
    case imap
}

/// Email account configuration
public struct EmailAccount: Identifiable, Codable, Sendable {
    public let id: UUID
    public let type: EmailAccountType
    public let email: String
    public var displayName: String?
    public var isConnected: Bool
    public var lastSyncDate: Date?

    public init(
        id: UUID = UUID(),
        type: EmailAccountType,
        email: String,
        displayName: String? = nil,
        isConnected: Bool = false,
        lastSyncDate: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.email = email
        self.displayName = displayName
        self.isConnected = isConnected
        self.lastSyncDate = lastSyncDate
    }
}

/// Service for email operations
public actor EmailService {
    private var accounts: [EmailAccount] = []
    private var emails: [String: [Email]] = [:] // accountId -> emails
    private var observers: [UUID: (EmailEvent) -> Void] = [:]

    public enum EmailError: Error, LocalizedError, Equatable {
        case notAuthenticated
        case accountNotFound
        case sendFailed(String)
        case fetchFailed(String)
        case connectionFailed(String)

        public var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "Email account not authenticated"
            case .accountNotFound:
                return "Email account not found"
            case .sendFailed(let message):
                return "Failed to send email: \(message)"
            case .fetchFailed(let message):
                return "Failed to fetch emails: \(message)"
            case .connectionFailed(let message):
                return "Connection failed: \(message)"
            }
        }
    }

    public enum EmailEvent: Sendable {
        case newEmail(Email)
        case emailUpdated(Email)
        case emailDeleted(String)
        case syncCompleted(String)
    }

    public init() {}

    // MARK: - Account Management

    /// Connect an email account
    public func connectAccount(_ account: EmailAccount) async throws {
        var connected = account
        connected.isConnected = true
        connected.lastSyncDate = Date()

        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = connected
        } else {
            accounts.append(connected)
        }
    }

    /// Disconnect an email account
    public func disconnectAccount(accountId: UUID) async throws {
        guard let index = accounts.firstIndex(where: { $0.id == accountId }) else {
            throw EmailError.accountNotFound
        }

        accounts[index].isConnected = false
        emails[accountId.uuidString] = nil
    }

    /// Get all connected accounts
    public func getAccounts() -> [EmailAccount] {
        return accounts
    }

    // MARK: - Email Operations

    /// Fetch emails for an account
    public func fetchEmails(accountId: UUID, limit: Int = 50) async throws -> [Email] {
        guard let account = accounts.first(where: { $0.id == accountId }),
              account.isConnected else {
            throw EmailError.notAuthenticated
        }

        // In production, this would call Gmail API, Apple Mail, etc.
        // For now, return cached emails
        return emails[accountId.uuidString] ?? []
    }

    /// Fetch unread emails
    public func fetchUnread(accountId: UUID) async throws -> [Email] {
        let allEmails = try await fetchEmails(accountId: accountId)
        return allEmails.filter { !$0.isRead }
    }

    /// Send an email
    public func sendEmail(_ email: Email, from accountId: UUID) async throws {
        guard let account = accounts.first(where: { $0.id == accountId }),
              account.isConnected else {
            throw EmailError.notAuthenticated
        }

        // In production, this would send via Gmail API, etc.
        // For now, just add to sent items
        var sentEmail = email
        sentEmail.labels.append("SENT")

        var accountEmails = emails[accountId.uuidString] ?? []
        accountEmails.append(sentEmail)
        emails[accountId.uuidString] = accountEmails
    }

    /// Mark email as read
    public func markAsRead(emailId: String, accountId: UUID) async throws {
        guard var accountEmails = emails[accountId.uuidString],
              let index = accountEmails.firstIndex(where: { $0.id == emailId }) else {
            return
        }

        accountEmails[index].isRead = true
        emails[accountId.uuidString] = accountEmails

        notifyObservers(.emailUpdated(accountEmails[index]))
    }

    /// Archive an email
    public func archive(emailId: String, accountId: UUID) async throws {
        guard var accountEmails = emails[accountId.uuidString],
              let index = accountEmails.firstIndex(where: { $0.id == emailId }) else {
            return
        }

        accountEmails[index].labels.removeAll { $0 == "INBOX" }
        accountEmails[index].labels.append("ARCHIVE")
        emails[accountId.uuidString] = accountEmails

        notifyObservers(.emailUpdated(accountEmails[index]))
    }

    /// Star/unstar an email
    public func toggleStar(emailId: String, accountId: UUID) async throws {
        guard var accountEmails = emails[accountId.uuidString],
              let index = accountEmails.firstIndex(where: { $0.id == emailId }) else {
            return
        }

        accountEmails[index].isStarred.toggle()
        emails[accountId.uuidString] = accountEmails

        notifyObservers(.emailUpdated(accountEmails[index]))
    }

    /// Delete an email
    public func delete(emailId: String, accountId: UUID) async throws {
        guard var accountEmails = emails[accountId.uuidString] else { return }

        accountEmails.removeAll { $0.id == emailId }
        emails[accountId.uuidString] = accountEmails

        notifyObservers(.emailDeleted(emailId))
    }

    // MARK: - Sync

    /// Sync emails for an account
    public func sync(accountId: UUID) async throws {
        guard let account = accounts.first(where: { $0.id == accountId }),
              account.isConnected else {
            throw EmailError.notAuthenticated
        }

        // Update last sync date
        if let index = accounts.firstIndex(where: { $0.id == accountId }) {
            accounts[index].lastSyncDate = Date()
        }

        notifyObservers(.syncCompleted(accountId.uuidString))
    }

    // MARK: - Observers

    /// Add an observer for email events
    public func addObserver(id: UUID, handler: @escaping @Sendable (EmailEvent) -> Void) {
        observers[id] = handler
    }

    /// Remove an observer
    public func removeObserver(id: UUID) {
        observers.removeValue(forKey: id)
    }

    private func notifyObservers(_ event: EmailEvent) {
        for handler in observers.values {
            handler(event)
        }
    }

    // MARK: - Testing Support

    /// Add emails for testing
    public func addTestEmails(_ testEmails: [Email], to accountId: UUID) {
        var accountEmails = emails[accountId.uuidString] ?? []
        accountEmails.append(contentsOf: testEmails)
        emails[accountId.uuidString] = accountEmails
    }
}
