import XCTest
@testable import JarvisCore

final class EmailServiceTests: XCTestCase {
    var service: EmailService!
    let testAccount = EmailAccount(type: .gmail, email: "test@example.com")

    override func setUp() async throws {
        service = EmailService()
    }

    // MARK: - Account Tests

    func testConnectAccount() async throws {
        try await service.connectAccount(testAccount)
        let accounts = await service.getAccounts()

        XCTAssertEqual(accounts.count, 1)
        XCTAssertTrue(accounts.first?.isConnected ?? false)
    }

    func testDisconnectAccount() async throws {
        try await service.connectAccount(testAccount)
        try await service.disconnectAccount(accountId: testAccount.id)

        let accounts = await service.getAccounts()
        XCTAssertFalse(accounts.first?.isConnected ?? true)
    }

    // MARK: - Email Operations Tests

    func testFetchEmailsRequiresAuth() async throws {
        do {
            _ = try await service.fetchEmails(accountId: testAccount.id)
            XCTFail("Should throw error")
        } catch let error as EmailService.EmailError {
            XCTAssertEqual(error, .notAuthenticated)
        }
    }

    func testFetchEmails() async throws {
        try await service.connectAccount(testAccount)

        let testEmail = Email(
            from: "sender@example.com",
            to: ["test@example.com"],
            subject: "Test Subject",
            body: "Test body"
        )
        await service.addTestEmails([testEmail], to: testAccount.id)

        let emails = try await service.fetchEmails(accountId: testAccount.id)
        XCTAssertEqual(emails.count, 1)
        XCTAssertEqual(emails.first?.subject, "Test Subject")
    }

    func testFetchUnread() async throws {
        try await service.connectAccount(testAccount)

        let readEmail = Email(from: "a@b.com", to: ["test@example.com"], subject: "Read", body: "", isRead: true)
        let unreadEmail = Email(from: "a@b.com", to: ["test@example.com"], subject: "Unread", body: "", isRead: false)
        await service.addTestEmails([readEmail, unreadEmail], to: testAccount.id)

        let unread = try await service.fetchUnread(accountId: testAccount.id)
        XCTAssertEqual(unread.count, 1)
        XCTAssertEqual(unread.first?.subject, "Unread")
    }

    func testSendEmail() async throws {
        try await service.connectAccount(testAccount)

        let email = Email(
            from: "test@example.com",
            to: ["recipient@example.com"],
            subject: "Test Send",
            body: "Test body"
        )

        try await service.sendEmail(email, from: testAccount.id)

        let sent = try await service.fetchEmails(accountId: testAccount.id)
        XCTAssertTrue(sent.first?.labels.contains("SENT") ?? false)
    }

    func testMarkAsRead() async throws {
        try await service.connectAccount(testAccount)

        let email = Email(from: "a@b.com", to: ["test@example.com"], subject: "Test", body: "", isRead: false)
        await service.addTestEmails([email], to: testAccount.id)

        try await service.markAsRead(emailId: email.id, accountId: testAccount.id)

        let emails = try await service.fetchEmails(accountId: testAccount.id)
        XCTAssertTrue(emails.first?.isRead ?? false)
    }

    func testArchiveEmail() async throws {
        try await service.connectAccount(testAccount)

        let email = Email(from: "a@b.com", to: ["test@example.com"], subject: "Test", body: "")
        await service.addTestEmails([email], to: testAccount.id)

        try await service.archive(emailId: email.id, accountId: testAccount.id)

        let emails = try await service.fetchEmails(accountId: testAccount.id)
        XCTAssertTrue(emails.first?.labels.contains("ARCHIVE") ?? false)
        XCTAssertFalse(emails.first?.labels.contains("INBOX") ?? true)
    }

    func testToggleStar() async throws {
        try await service.connectAccount(testAccount)

        let email = Email(from: "a@b.com", to: ["test@example.com"], subject: "Test", body: "", isStarred: false)
        await service.addTestEmails([email], to: testAccount.id)

        try await service.toggleStar(emailId: email.id, accountId: testAccount.id)

        let emails = try await service.fetchEmails(accountId: testAccount.id)
        XCTAssertTrue(emails.first?.isStarred ?? false)
    }

    func testDeleteEmail() async throws {
        try await service.connectAccount(testAccount)

        let email = Email(from: "a@b.com", to: ["test@example.com"], subject: "Test", body: "")
        await service.addTestEmails([email], to: testAccount.id)

        try await service.delete(emailId: email.id, accountId: testAccount.id)

        let emails = try await service.fetchEmails(accountId: testAccount.id)
        XCTAssertTrue(emails.isEmpty)
    }

    // MARK: - Model Tests

    func testEmailInit() {
        let email = Email(
            from: "sender@test.com",
            to: ["recipient@test.com"],
            cc: ["cc@test.com"],
            subject: "Test",
            body: "Body"
        )

        XCTAssertEqual(email.from, "sender@test.com")
        XCTAssertEqual(email.to, ["recipient@test.com"])
        XCTAssertEqual(email.cc, ["cc@test.com"])
        XCTAssertFalse(email.isRead)
        XCTAssertTrue(email.labels.contains("INBOX"))
    }

    func testEmailAccountInit() {
        let account = EmailAccount(type: .gmail, email: "test@gmail.com", displayName: "Test User")

        XCTAssertEqual(account.type, .gmail)
        XCTAssertEqual(account.email, "test@gmail.com")
        XCTAssertEqual(account.displayName, "Test User")
        XCTAssertFalse(account.isConnected)
    }

    func testEmailErrorDescriptions() {
        let notAuth = EmailService.EmailError.notAuthenticated
        XCTAssertTrue(notAuth.errorDescription?.contains("not authenticated") ?? false)

        let notFound = EmailService.EmailError.accountNotFound
        XCTAssertTrue(notFound.errorDescription?.contains("not found") ?? false)

        let sendFailed = EmailService.EmailError.sendFailed("test")
        XCTAssertTrue(sendFailed.errorDescription?.contains("test") ?? false)
    }
}
