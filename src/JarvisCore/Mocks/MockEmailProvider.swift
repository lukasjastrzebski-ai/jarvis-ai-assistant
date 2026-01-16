import Foundation

/// Mock email provider for integration testing without Gmail API
public actor MockEmailProvider {
    private var mockEmails: [String: [Email]] = [:]
    private var mockAccounts: [EmailAccount] = []

    public init() {
        // Pre-populate with rich sample data from SampleDataGenerator
        let testAccountId = UUID()
        let testAccount = EmailAccount(
            id: testAccountId,
            type: .gmail,
            email: "user@jarvis.app",
            displayName: "Jarvis User",
            isConnected: true,
            lastSyncDate: Date()
        )
        mockAccounts.append(testAccount)

        // Use SampleDataGenerator for rich, realistic email data
        let emails = SampleDataGenerator.shared.generateSampleEmails()
        mockEmails[testAccountId.uuidString] = emails
    }

    private func seedTestData() {
        // Kept for potential future use but init handles seeding now
        let testAccountId = UUID()
        let testAccount = EmailAccount(
            id: testAccountId,
            type: .gmail,
            email: "test@example.com",
            displayName: "Test User",
            isConnected: true,
            lastSyncDate: Date()
        )
        mockAccounts.append(testAccount)

        // Create mock emails
        let emails: [Email] = [
            Email(
                from: "boss@company.com",
                to: ["test@example.com"],
                subject: "Q4 Planning Meeting",
                body: "Let's discuss Q4 priorities tomorrow at 10am.",
                date: Date().addingTimeInterval(-3600),
                isRead: false
            ),
            Email(
                from: "team@startup.io",
                to: ["test@example.com"],
                subject: "Your Weekly Summary",
                body: "Here's what happened this week...",
                date: Date().addingTimeInterval(-7200),
                isRead: true
            ),
            Email(
                from: "noreply@calendar.google.com",
                to: ["test@example.com"],
                subject: "Event Reminder: Dentist Appointment",
                body: "Reminder: You have an appointment tomorrow at 2pm.",
                date: Date().addingTimeInterval(-86400),
                isRead: false
            ),
            Email(
                from: "friend@gmail.com",
                to: ["test@example.com"],
                subject: "Lunch this weekend?",
                body: "Hey! Want to grab lunch on Saturday?",
                date: Date().addingTimeInterval(-172800),
                isRead: true,
                isStarred: true
            ),
            Email(
                from: "newsletter@techsite.com",
                to: ["test@example.com"],
                subject: "This Week in Tech",
                body: "The latest news in technology...",
                date: Date().addingTimeInterval(-259200),
                isRead: true
            )
        ]

        mockEmails[testAccountId.uuidString] = emails
    }

    // MARK: - Mock API Methods

    public func getAccounts() -> [EmailAccount] {
        return mockAccounts
    }

    public func getEmails(for accountId: UUID) -> [Email] {
        return mockEmails[accountId.uuidString] ?? []
    }

    public func getUnreadEmails(for accountId: UUID) -> [Email] {
        return getEmails(for: accountId).filter { !$0.isRead }
    }

    public func markAsRead(emailId: String, accountId: UUID) {
        guard var emails = mockEmails[accountId.uuidString],
              let index = emails.firstIndex(where: { $0.id == emailId }) else {
            return
        }
        emails[index].isRead = true
        mockEmails[accountId.uuidString] = emails
    }

    public func sendEmail(_ email: Email, from accountId: UUID) {
        var sentEmail = email
        sentEmail.labels = ["SENT"]
        var emails = mockEmails[accountId.uuidString] ?? []
        emails.insert(sentEmail, at: 0)
        mockEmails[accountId.uuidString] = emails
    }

    public func addMockEmail(_ email: Email, to accountId: UUID) {
        var emails = mockEmails[accountId.uuidString] ?? []
        emails.insert(email, at: 0)
        mockEmails[accountId.uuidString] = emails
    }
}
