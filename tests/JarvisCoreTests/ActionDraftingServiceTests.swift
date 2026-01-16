import XCTest
@testable import JarvisCore

final class ActionDraftingServiceTests: XCTestCase {
    var service: ActionDraftingService!

    override func setUp() async throws {
        service = ActionDraftingService()
    }

    // MARK: - Draft Generation Tests

    func testGenerateDraftEmailReply() async throws {
        let request = ActionDraftingService.DraftRequest(
            type: .emailReply,
            context: "Previous email about project status",
            recipient: "John",
            intent: "Accept the meeting",
            tone: .professional
        )

        let draft = try await service.generateDraft(request)

        XCTAssertFalse(draft.content.isEmpty)
        XCTAssertTrue(draft.content.contains("John"))
        XCTAssertGreaterThan(draft.confidence, 0)
    }

    func testGenerateDraftNewEmail() async throws {
        let request = ActionDraftingService.DraftRequest(
            type: .emailNew,
            recipient: "Sarah",
            intent: "Schedule a meeting",
            tone: .friendly
        )

        let draft = try await service.generateDraft(request)

        XCTAssertFalse(draft.content.isEmpty)
        XCTAssertNotNil(draft.subject)
        XCTAssertTrue(draft.content.contains("Sarah"))
    }

    func testGenerateDraftMessage() async throws {
        let request = ActionDraftingService.DraftRequest(
            type: .message,
            intent: "Follow up on the project",
            tone: .casual
        )

        let draft = try await service.generateDraft(request)

        XCTAssertFalse(draft.content.isEmpty)
        XCTAssertNil(draft.subject) // Messages don't have subjects
    }

    func testGenerateMultipleDrafts() async throws {
        let request = ActionDraftingService.DraftRequest(
            type: .emailReply,
            intent: "Decline politely",
            tone: .professional
        )

        let drafts = try await service.generateDrafts(request, count: 3)

        XCTAssertEqual(drafts.count, 3)
        // Each draft should have different content or tone
        let firstContent = drafts[0].content
        let secondContent = drafts[1].content
        // They should be generated (content exists)
        XCTAssertFalse(firstContent.isEmpty)
        XCTAssertFalse(secondContent.isEmpty)
    }

    // MARK: - Tone Tests

    func testDraftWithFriendlyTone() async throws {
        let request = ActionDraftingService.DraftRequest(
            type: .emailReply,
            recipient: "Mike",
            intent: "Thank you",
            tone: .friendly
        )

        let draft = try await service.generateDraft(request)

        XCTAssertTrue(draft.content.contains("Hi"))
    }

    func testDraftWithFormalTone() async throws {
        let request = ActionDraftingService.DraftRequest(
            type: .emailReply,
            recipient: "Dr. Smith",
            intent: "Request information",
            tone: .formal
        )

        let draft = try await service.generateDraft(request)

        XCTAssertTrue(draft.content.contains("Dear"))
    }

    func testDraftWithCasualTone() async throws {
        let request = ActionDraftingService.DraftRequest(
            type: .emailReply,
            recipient: "Tom",
            intent: "Confirm plans",
            tone: .casual
        )

        let draft = try await service.generateDraft(request)

        XCTAssertTrue(draft.content.contains("Hey"))
    }

    func testDraftWithEnthusiasticTone() async throws {
        let request = ActionDraftingService.DraftRequest(
            type: .emailNew,
            recipient: "Team",
            intent: "Announce good news",
            tone: .enthusiastic
        )

        let draft = try await service.generateDraft(request)

        XCTAssertTrue(draft.content.contains("!"))
    }

    // MARK: - Intent-Based Content Tests

    func testAcceptIntent() async throws {
        let request = ActionDraftingService.DraftRequest(
            type: .emailReply,
            intent: "Accept the invitation",
            tone: .professional
        )

        let draft = try await service.generateDraft(request)

        XCTAssertTrue(draft.content.contains("happy to confirm") || draft.content.contains("Thank you"))
    }

    func testDeclineIntent() async throws {
        let request = ActionDraftingService.DraftRequest(
            type: .emailReply,
            intent: "Decline the offer",
            tone: .professional
        )

        let draft = try await service.generateDraft(request)

        XCTAssertTrue(draft.content.contains("Unfortunately") || draft.content.contains("won't be able"))
    }

    func testRescheduleIntent() async throws {
        let request = ActionDraftingService.DraftRequest(
            type: .emailReply,
            intent: "Reschedule to later",
            tone: .professional
        )

        let draft = try await service.generateDraft(request)

        XCTAssertTrue(draft.content.contains("reschedule") || draft.content.contains("next week"))
    }

    func testFollowUpIntent() async throws {
        let request = ActionDraftingService.DraftRequest(
            type: .emailReply,
            intent: "Follow up on the proposal",
            tone: .professional
        )

        let draft = try await service.generateDraft(request)

        XCTAssertTrue(draft.content.contains("follow up"))
    }

    // MARK: - Quick Command Tests

    func testQuickCommandReplyYes() async throws {
        let draft = try await service.processQuickCommand("reply yes", context: nil)

        XCTAssertFalse(draft.content.isEmpty)
        XCTAssertTrue(draft.content.contains("confirm") || draft.content.contains("happy"))
    }

    func testQuickCommandReplyNo() async throws {
        let draft = try await service.processQuickCommand("reply no", context: nil)

        XCTAssertFalse(draft.content.isEmpty)
        XCTAssertTrue(draft.content.contains("Unfortunately") || draft.content.contains("won't"))
    }

    func testQuickCommandReplyLater() async throws {
        let draft = try await service.processQuickCommand("reply later next week", context: nil)

        XCTAssertFalse(draft.content.isEmpty)
        XCTAssertTrue(draft.content.contains("reschedule") || draft.content.contains("next week"))
    }

    // MARK: - Writing Style Tests

    func testSetWritingStyle() async {
        await service.setWritingStyle(.formal)
        let style = await service.getWritingStyle()
        XCTAssertEqual(style, .formal)
    }

    func testDefaultWritingStyle() async {
        let style = await service.getWritingStyle()
        XCTAssertEqual(style, .balanced)
    }

    // MARK: - Learning Tests

    func testRecordEdit() async {
        let request = ActionDraftingService.DraftRequest(
            type: .emailReply,
            intent: "Test",
            tone: .professional
        )

        // Record an edit - this should not throw
        await service.recordEdit(
            request: request,
            original: "Original draft",
            edited: "Edited draft"
        )

        // The service should track this for learning (verified by not crashing)
    }

    // MARK: - Confidence Tests

    func testConfidenceIncreasesWithContext() async throws {
        let requestWithoutContext = ActionDraftingService.DraftRequest(
            type: .emailReply,
            intent: "Test",
            tone: .professional
        )

        let requestWithContext = ActionDraftingService.DraftRequest(
            type: .emailReply,
            context: "Previous conversation about the project",
            recipient: "John",
            intent: "Test",
            tone: .professional
        )

        let draftWithout = try await service.generateDraft(requestWithoutContext)
        let draftWith = try await service.generateDraft(requestWithContext)

        XCTAssertGreaterThan(draftWith.confidence, draftWithout.confidence)
    }

    // MARK: - Model Tests

    func testDraftRequestInit() {
        let request = ActionDraftingService.DraftRequest(
            type: .emailNew,
            context: "Context",
            recipient: "Test",
            intent: "Test intent",
            tone: .formal,
            maxLength: 500
        )

        XCTAssertEqual(request.type, .emailNew)
        XCTAssertEqual(request.context, "Context")
        XCTAssertEqual(request.recipient, "Test")
        XCTAssertEqual(request.intent, "Test intent")
        XCTAssertEqual(request.tone, .formal)
        XCTAssertEqual(request.maxLength, 500)
    }

    func testDraftInit() {
        let draft = ActionDraftingService.Draft(
            content: "Test content",
            subject: "Test Subject",
            alternatives: ["Alt 1", "Alt 2"],
            confidence: 0.85
        )

        XCTAssertEqual(draft.content, "Test content")
        XCTAssertEqual(draft.subject, "Test Subject")
        XCTAssertEqual(draft.alternatives.count, 2)
        XCTAssertEqual(draft.confidence, 0.85)
    }

    func testWritingStyleCases() {
        let allCases = ActionDraftingService.WritingStyle.allCases
        XCTAssertTrue(allCases.contains(.formal))
        XCTAssertTrue(allCases.contains(.balanced))
        XCTAssertTrue(allCases.contains(.casual))
        XCTAssertTrue(allCases.contains(.brief))
    }

    func testToneCases() {
        let allCases = ActionDraftingService.Tone.allCases
        XCTAssertTrue(allCases.contains(.friendly))
        XCTAssertTrue(allCases.contains(.professional))
        XCTAssertTrue(allCases.contains(.formal))
        XCTAssertTrue(allCases.contains(.casual))
        XCTAssertTrue(allCases.contains(.urgent))
        XCTAssertTrue(allCases.contains(.neutral))
        XCTAssertTrue(allCases.contains(.apologetic))
        XCTAssertTrue(allCases.contains(.enthusiastic))
    }

    func testDraftTypeCases() {
        let emailReply = ActionDraftingService.DraftType.emailReply
        let emailNew = ActionDraftingService.DraftType.emailNew
        let message = ActionDraftingService.DraftType.message
        let note = ActionDraftingService.DraftType.note
        let summary = ActionDraftingService.DraftType.summary

        XCTAssertEqual(emailReply.rawValue, "emailReply")
        XCTAssertEqual(emailNew.rawValue, "emailNew")
        XCTAssertEqual(message.rawValue, "message")
        XCTAssertEqual(note.rawValue, "note")
        XCTAssertEqual(summary.rawValue, "summary")
    }
}
