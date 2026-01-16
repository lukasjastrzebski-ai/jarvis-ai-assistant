import XCTest
@testable import JarvisCore

final class VoiceServiceTests: XCTestCase {

    // MARK: - VoiceCommandParser Tests

    func testParseWhatMattersToday() {
        let command = VoiceCommandParser.parse("What matters today?")

        XCTAssertNotNil(command)
        XCTAssertEqual(command?.type, .whatMattersToday)
        XCTAssertFalse(command?.requiresConfirmation ?? true)
    }

    func testParsePlanMyDay() {
        let command = VoiceCommandParser.parse("Plan my day")

        XCTAssertNotNil(command)
        XCTAssertEqual(command?.type, .planDay)
    }

    func testParseShowSchedule() {
        let command = VoiceCommandParser.parse("show my schedule")

        XCTAssertNotNil(command)
        XCTAssertEqual(command?.type, .showSchedule)
    }

    func testParseSendEmail() {
        let command = VoiceCommandParser.parse("Send email to John about the meeting")

        XCTAssertNotNil(command)
        XCTAssertEqual(command?.type, .sendEmail)
        XCTAssertTrue(command?.requiresConfirmation ?? false)
        XCTAssertEqual(command?.parameters["recipient"], "john")
    }

    func testParseReplyEmail() {
        let command = VoiceCommandParser.parse("Reply to that email")

        XCTAssertNotNil(command)
        XCTAssertEqual(command?.type, .replyEmail)
        XCTAssertTrue(command?.requiresConfirmation ?? false)
    }

    func testParseScheduleMeeting() {
        let command = VoiceCommandParser.parse("Schedule meeting with Sarah")

        XCTAssertNotNil(command)
        XCTAssertEqual(command?.type, .scheduleMeeting)
        XCTAssertTrue(command?.requiresConfirmation ?? false)
        XCTAssertEqual(command?.parameters["attendee"], "sarah")
    }

    func testParseAddTask() {
        let command = VoiceCommandParser.parse("Add task review the quarterly report")

        XCTAssertNotNil(command)
        XCTAssertEqual(command?.type, .addTask)
        XCTAssertEqual(command?.parameters["title"], "review the quarterly report")
    }

    func testParseCompleteTask() {
        let command = VoiceCommandParser.parse("Mark done the first task")

        XCTAssertNotNil(command)
        XCTAssertEqual(command?.type, .completeTask)
    }

    func testParseShowTasks() {
        let command = VoiceCommandParser.parse("Show tasks")

        XCTAssertNotNil(command)
        XCTAssertEqual(command?.type, .showTasks)
    }

    func testParsePriorityCheck() {
        let command = VoiceCommandParser.parse("What's my highest priority?")

        XCTAssertNotNil(command)
        XCTAssertEqual(command?.type, .priorityCheck)
    }

    func testParseUndo() {
        let command = VoiceCommandParser.parse("Undo that")

        XCTAssertNotNil(command)
        XCTAssertEqual(command?.type, .undo)
    }

    func testParseCancel() {
        let command = VoiceCommandParser.parse("Cancel")

        XCTAssertNotNil(command)
        XCTAssertEqual(command?.type, .cancel)
    }

    func testParseHelp() {
        let command = VoiceCommandParser.parse("Help me")

        XCTAssertNotNil(command)
        XCTAssertEqual(command?.type, .help)
    }

    func testParseShowAgain() {
        let command = VoiceCommandParser.parse("Show that again please")

        XCTAssertNotNil(command)
        XCTAssertEqual(command?.type, .showAgain)
    }

    func testParseUnknownCommand() {
        let command = VoiceCommandParser.parse("blah blah random words")

        XCTAssertNil(command)
    }

    func testParseCaseInsensitive() {
        let command = VoiceCommandParser.parse("WHAT MATTERS TODAY")

        XCTAssertNotNil(command)
        XCTAssertEqual(command?.type, .whatMattersToday)
    }

    func testParseWithConfidence() {
        let command = VoiceCommandParser.parse("Plan my day", confidence: 0.85)

        XCTAssertNotNil(command)
        XCTAssertEqual(command?.confidence, 0.85)
    }

    // MARK: - VoiceCommand Tests

    func testVoiceCommandInit() {
        let command = VoiceCommand(
            type: .addTask,
            rawText: "Add task test",
            parameters: ["title": "test"],
            confidence: 0.9,
            requiresConfirmation: false
        )

        XCTAssertEqual(command.type, .addTask)
        XCTAssertEqual(command.rawText, "Add task test")
        XCTAssertEqual(command.parameters["title"], "test")
        XCTAssertEqual(command.confidence, 0.9)
        XCTAssertFalse(command.requiresConfirmation)
    }

    // MARK: - VoiceCommandType Tests

    func testVoiceCommandTypeAllCases() {
        XCTAssertEqual(VoiceCommandType.allCases.count, 18)
    }

    func testVoiceCommandTypeRawValues() {
        XCTAssertEqual(VoiceCommandType.planDay.rawValue, "plan_day")
        XCTAssertEqual(VoiceCommandType.sendEmail.rawValue, "send_email")
        XCTAssertEqual(VoiceCommandType.addTask.rawValue, "add_task")
    }

    // MARK: - VoiceService Tests

    func testVoiceServiceInit() async {
        let service = VoiceService()
        let isListening = await service.isCurrentlyListening()

        XCTAssertFalse(isListening)
    }

    // MARK: - RecognitionResult Tests

    func testRecognitionResult() {
        let result = VoiceService.RecognitionResult(
            text: "Hello world",
            isFinal: true,
            confidence: 0.95
        )

        XCTAssertEqual(result.text, "Hello world")
        XCTAssertTrue(result.isFinal)
        XCTAssertEqual(result.confidence, 0.95)
    }

    // MARK: - VoiceError Tests

    func testVoiceErrorDescriptions() {
        let notAuthorized = VoiceService.VoiceError.notAuthorized
        XCTAssertTrue(notAuthorized.errorDescription?.contains("not authorized") ?? false)

        let notAvailable = VoiceService.VoiceError.notAvailable
        XCTAssertTrue(notAvailable.errorDescription?.contains("not available") ?? false)

        let recognitionFailed = VoiceService.VoiceError.recognitionFailed("test")
        XCTAssertTrue(recognitionFailed.errorDescription?.contains("test") ?? false)

        let audioFailed = VoiceService.VoiceError.audioSessionFailed("audio test")
        XCTAssertTrue(audioFailed.errorDescription?.contains("audio test") ?? false)
    }
}
