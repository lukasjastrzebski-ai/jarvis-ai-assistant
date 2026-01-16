import Foundation
#if canImport(Speech)
import Speech
import AVFoundation
#endif

/// Service for voice recognition and speech synthesis
public actor VoiceService {
    // MARK: - Properties

    private var isListening: Bool = false
    private var recognitionTask: Any? = nil
    private var audioEngine: Any? = nil

    public enum VoiceError: Error, LocalizedError {
        case notAuthorized
        case notAvailable
        case recognitionFailed(String)
        case audioSessionFailed(String)

        public var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Speech recognition not authorized"
            case .notAvailable:
                return "Speech recognition not available"
            case .recognitionFailed(let message):
                return "Recognition failed: \(message)"
            case .audioSessionFailed(let message):
                return "Audio session failed: \(message)"
            }
        }
    }

    public struct RecognitionResult: Sendable {
        public let text: String
        public let isFinal: Bool
        public let confidence: Float

        public init(text: String, isFinal: Bool, confidence: Float) {
            self.text = text
            self.isFinal = isFinal
            self.confidence = confidence
        }
    }

    public init() {}

    // MARK: - Authorization

    /// Check if speech recognition is authorized
    public func isAuthorized() -> Bool {
        #if canImport(Speech)
        return SFSpeechRecognizer.authorizationStatus() == .authorized
        #else
        return false
        #endif
    }

    /// Request authorization for speech recognition
    public func requestAuthorization() async -> Bool {
        #if canImport(Speech)
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        #else
        return false
        #endif
    }

    /// Check if voice recognition is currently active
    public func isCurrentlyListening() -> Bool {
        return isListening
    }

    // MARK: - Recognition

    /// Start listening for voice input
    /// Returns an AsyncStream of recognition results
    public func startListening() async throws -> AsyncStream<RecognitionResult> {
        #if canImport(Speech)
        guard isAuthorized() else {
            throw VoiceError.notAuthorized
        }

        guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
            throw VoiceError.notAvailable
        }

        isListening = true

        return AsyncStream { continuation in
            Task { @MainActor in
                do {
                    let audioEngine = AVAudioEngine()
                    let request = SFSpeechAudioBufferRecognitionRequest()
                    request.shouldReportPartialResults = true

                    let inputNode = audioEngine.inputNode
                    let recordingFormat = inputNode.outputFormat(forBus: 0)

                    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                        request.append(buffer)
                    }

                    audioEngine.prepare()
                    try audioEngine.start()

                    let recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                        if let result = result {
                            let confidence = result.bestTranscription.segments.first?.confidence ?? 0.0
                            let recognitionResult = RecognitionResult(
                                text: result.bestTranscription.formattedString,
                                isFinal: result.isFinal,
                                confidence: confidence
                            )
                            continuation.yield(recognitionResult)

                            if result.isFinal {
                                continuation.finish()
                            }
                        }

                        if let error = error {
                            continuation.finish()
                        }
                    }

                    continuation.onTermination = { @Sendable _ in
                        audioEngine.stop()
                        inputNode.removeTap(onBus: 0)
                        recognitionTask.cancel()
                    }
                } catch {
                    continuation.finish()
                }
            }
        }
        #else
        throw VoiceError.notAvailable
        #endif
    }

    /// Stop listening
    public func stopListening() {
        isListening = false
        // The actual stopping is handled by the AsyncStream termination
    }
}

/// Voice command types
public enum VoiceCommandType: String, Codable, Sendable, CaseIterable {
    // Planning commands
    case planDay = "plan_day"
    case whatMattersToday = "what_matters"
    case showSchedule = "show_schedule"

    // Email commands
    case sendEmail = "send_email"
    case replyEmail = "reply_email"
    case draftEmail = "draft_email"
    case readEmail = "read_email"

    // Calendar commands
    case scheduleMeeting = "schedule_meeting"
    case showNextEvent = "show_next"
    case checkAvailability = "check_availability"

    // Task commands
    case addTask = "add_task"
    case completeTask = "complete_task"
    case showTasks = "show_tasks"
    case priorityCheck = "priority_check"

    // Meta commands
    case undo = "undo"
    case cancel = "cancel"
    case help = "help"
    case showAgain = "show_again"
}

/// Parsed voice command
public struct VoiceCommand: Sendable {
    public let type: VoiceCommandType
    public let rawText: String
    public let parameters: [String: String]
    public let confidence: Float
    public let requiresConfirmation: Bool

    public init(
        type: VoiceCommandType,
        rawText: String,
        parameters: [String: String] = [:],
        confidence: Float,
        requiresConfirmation: Bool = false
    ) {
        self.type = type
        self.rawText = rawText
        self.parameters = parameters
        self.confidence = confidence
        self.requiresConfirmation = requiresConfirmation
    }
}

/// Parser for voice commands using pattern matching
public struct VoiceCommandParser {
    private static let patterns: [(pattern: String, type: VoiceCommandType, requiresConfirmation: Bool)] = [
        // Planning
        ("what matters today", .whatMattersToday, false),
        ("what's important today", .whatMattersToday, false),
        ("plan my day", .planDay, false),
        ("show my schedule", .showSchedule, false),
        ("what's next", .showNextEvent, false),

        // Email - require confirmation for sends
        ("send email to", .sendEmail, true),
        ("reply to", .replyEmail, true),
        ("draft email", .draftEmail, false),
        ("read email", .readEmail, false),

        // Calendar - require confirmation for scheduling
        ("schedule meeting", .scheduleMeeting, true),
        ("schedule a meeting", .scheduleMeeting, true),
        ("check availability", .checkAvailability, false),
        ("am i free", .checkAvailability, false),

        // Tasks
        ("add task", .addTask, false),
        ("create task", .addTask, false),
        ("complete", .completeTask, false),
        ("mark done", .completeTask, false),
        ("show tasks", .showTasks, false),
        ("what's my priority", .priorityCheck, false),
        ("highest priority", .priorityCheck, false),

        // Meta
        ("undo", .undo, false),
        ("cancel", .cancel, false),
        ("help", .help, false),
        ("show that again", .showAgain, false),
        ("repeat", .showAgain, false),
    ]

    /// Parse a voice input into a command
    public static func parse(_ input: String, confidence: Float = 1.0) -> VoiceCommand? {
        let lowercased = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        for (pattern, type, requiresConfirmation) in patterns {
            if lowercased.contains(pattern) {
                let parameters = extractParameters(from: lowercased, for: type)
                return VoiceCommand(
                    type: type,
                    rawText: input,
                    parameters: parameters,
                    confidence: confidence,
                    requiresConfirmation: requiresConfirmation
                )
            }
        }

        return nil
    }

    private static func extractParameters(from input: String, for type: VoiceCommandType) -> [String: String] {
        var params: [String: String] = [:]

        switch type {
        case .sendEmail, .replyEmail, .draftEmail:
            // Extract recipient if mentioned
            if let toIndex = input.range(of: " to ") {
                let afterTo = String(input[toIndex.upperBound...])
                let recipient = afterTo.components(separatedBy: " ").first ?? afterTo
                params["recipient"] = recipient
            }

        case .scheduleMeeting:
            // Extract attendee if mentioned
            if let withIndex = input.range(of: " with ") {
                let afterWith = String(input[withIndex.upperBound...])
                let attendee = afterWith.components(separatedBy: " ").first ?? afterWith
                params["attendee"] = attendee
            }

        case .addTask:
            // Extract task title (everything after "add task" or "create task")
            if let taskIndex = input.range(of: "task ") {
                let taskTitle = String(input[taskIndex.upperBound...])
                if !taskTitle.isEmpty {
                    params["title"] = taskTitle
                }
            }

        default:
            break
        }

        return params
    }
}
