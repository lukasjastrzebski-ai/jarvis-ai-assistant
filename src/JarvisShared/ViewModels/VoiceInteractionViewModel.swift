import SwiftUI
import JarvisCore

/// State for voice interaction
public enum VoiceState: Equatable {
    case idle
    case listening
    case processing
    case responding
    case error(String)

    public var isActive: Bool {
        switch self {
        case .listening, .processing:
            return true
        default:
            return false
        }
    }
}

/// View model for voice interaction
@MainActor
public class VoiceInteractionViewModel: ObservableObject {
    // MARK: - Published State

    @Published public var state: VoiceState = .idle
    @Published public var transcribedText: String = ""
    @Published public var currentCommand: VoiceCommand?
    @Published public var responseText: String = ""
    @Published public var showConfirmation: Bool = false
    @Published public var isAuthorized: Bool = false
    @Published public var confidenceLevel: Float = 0.0

    // MARK: - Dependencies

    private let voiceService: VoiceService
    private var listeningTask: Task<Void, Never>?

    // MARK: - Initialization

    public init(voiceService: VoiceService) {
        self.voiceService = voiceService
        Task {
            await checkAuthorization()
        }
    }

    // MARK: - Authorization

    private func checkAuthorization() async {
        isAuthorized = await voiceService.isAuthorized()
    }

    /// Request microphone and speech authorization
    public func requestAuthorization() async {
        isAuthorized = await voiceService.requestAuthorization()
    }

    // MARK: - Voice Interaction

    /// Start listening for voice commands
    public func startListening() {
        guard isAuthorized else {
            state = .error("Voice recognition not authorized")
            return
        }

        state = .listening
        transcribedText = ""
        currentCommand = nil
        responseText = ""

        listeningTask = Task {
            do {
                let stream = try await voiceService.startListening()
                for await result in stream {
                    await handleRecognitionResult(result)
                }
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    /// Stop listening
    public func stopListening() {
        listeningTask?.cancel()
        listeningTask = nil
        Task {
            await voiceService.stopListening()
        }

        // Process final transcription if we have text
        if !transcribedText.isEmpty {
            processCommand()
        } else {
            state = .idle
        }
    }

    /// Toggle listening state
    public func toggleListening() {
        if state.isActive {
            stopListening()
        } else {
            startListening()
        }
    }

    // MARK: - Command Processing

    private func handleRecognitionResult(_ result: VoiceService.RecognitionResult) async {
        transcribedText = result.text
        confidenceLevel = result.confidence

        if result.isFinal {
            processCommand()
        }
    }

    private func processCommand() {
        state = .processing

        // Parse the transcribed text
        if let command = VoiceCommandParser.parse(transcribedText, confidence: confidenceLevel) {
            currentCommand = command

            if command.requiresConfirmation {
                // Show confirmation dialog
                showConfirmation = true
                state = .responding
            } else {
                // Execute directly
                executeCommand(command)
            }
        } else {
            // Couldn't parse command
            responseText = "I didn't understand that. Try saying 'help' for available commands."
            state = .responding
        }
    }

    /// Execute a confirmed command
    public func executeCommand(_ command: VoiceCommand) {
        state = .processing

        // Generate response based on command type
        responseText = generateResponse(for: command)
        state = .responding

        // Auto-dismiss after delay
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            if state == .responding {
                reset()
            }
        }
    }

    /// Confirm and execute pending command
    public func confirmCommand() {
        showConfirmation = false
        if let command = currentCommand {
            executeCommand(command)
        }
    }

    /// Cancel pending command
    public func cancelCommand() {
        showConfirmation = false
        currentCommand = nil
        reset()
    }

    /// Reset to idle state
    public func reset() {
        state = .idle
        transcribedText = ""
        currentCommand = nil
        responseText = ""
        showConfirmation = false
    }

    // MARK: - Response Generation

    private func generateResponse(for command: VoiceCommand) -> String {
        switch command.type {
        case .whatMattersToday:
            return "Your top priorities today are: 1) Review Q4 report, 2) Team standup at 10am, 3) Client call at 2pm."

        case .planDay:
            return "Here's your day plan: 3 meetings, 5 tasks. First up is team standup in 30 minutes."

        case .showSchedule:
            return "You have 3 events today. Next: Team standup at 10:00 AM."

        case .showNextEvent:
            return "Your next event is Team standup at 10:00 AM in the Main Conference Room."

        case .sendEmail:
            let recipient = command.parameters["recipient"] ?? "someone"
            return "Email sent to \(recipient)."

        case .replyEmail:
            return "Reply sent."

        case .draftEmail:
            return "I've drafted the email. Ready for your review."

        case .readEmail:
            return "You have 12 unread emails. The most recent is from John about the project update."

        case .scheduleMeeting:
            let attendee = command.parameters["attendee"] ?? "the team"
            return "Meeting scheduled with \(attendee)."

        case .checkAvailability:
            return "You're free from 3pm to 5pm today."

        case .addTask:
            let title = command.parameters["title"] ?? "new task"
            return "Task added: \(title)"

        case .completeTask:
            return "Task marked as complete."

        case .showTasks:
            return "You have 5 tasks today. 2 are high priority."

        case .priorityCheck:
            return "Your highest priority is 'Review Q4 report' due by end of day."

        case .undo:
            return "Last action undone."

        case .cancel:
            return "Cancelled."

        case .help:
            return "Try saying: 'What matters today?', 'Plan my day', 'Add task...', or 'Schedule meeting with...'"

        case .showAgain:
            return "Showing previous response again."
        }
    }
}
