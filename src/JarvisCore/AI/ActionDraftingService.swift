import Foundation

/// Service for AI-powered action drafting (email responses, messages, etc.)
public actor ActionDraftingService {
    // MARK: - Properties

    private var userWritingStyle: WritingStyle = .balanced
    private var draftHistory: [DraftHistoryEntry] = []

    public init() {}

    // MARK: - Types

    /// Writing style preferences
    public enum WritingStyle: String, Codable, Sendable, CaseIterable {
        case formal
        case balanced
        case casual
        case brief
    }

    /// Tone for generated content
    public enum Tone: String, Codable, Sendable, CaseIterable {
        case friendly
        case professional
        case formal
        case casual
        case urgent
        case neutral
        case apologetic
        case enthusiastic
    }

    /// Draft request
    public struct DraftRequest: Sendable {
        public let type: DraftType
        public let context: String?
        public let recipient: String?
        public let intent: String
        public let tone: Tone
        public let maxLength: Int?

        public init(
            type: DraftType,
            context: String? = nil,
            recipient: String? = nil,
            intent: String,
            tone: Tone = .professional,
            maxLength: Int? = nil
        ) {
            self.type = type
            self.context = context
            self.recipient = recipient
            self.intent = intent
            self.tone = tone
            self.maxLength = maxLength
        }
    }

    /// Type of draft to generate
    public enum DraftType: String, Codable, Sendable {
        case emailReply
        case emailNew
        case message
        case note
        case summary
    }

    /// Generated draft
    public struct Draft: Identifiable, Sendable {
        public let id: UUID
        public let content: String
        public let subject: String?
        public let alternatives: [String]
        public let confidence: Double
        public let generatedAt: Date

        public init(
            id: UUID = UUID(),
            content: String,
            subject: String? = nil,
            alternatives: [String] = [],
            confidence: Double,
            generatedAt: Date = Date()
        ) {
            self.id = id
            self.content = content
            self.subject = subject
            self.alternatives = alternatives
            self.confidence = confidence
            self.generatedAt = generatedAt
        }
    }

    /// History entry for learning from edits
    public struct DraftHistoryEntry: Sendable {
        public let request: DraftRequest
        public let originalDraft: String
        public let finalDraft: String
        public let wasEdited: Bool
        public let date: Date
    }

    // MARK: - Draft Generation

    /// Generate a draft based on request
    public func generateDraft(_ request: DraftRequest) async throws -> Draft {
        // In production, this would call an LLM API
        // For now, use template-based generation
        let content = generateContent(for: request)
        let subject = generateSubject(for: request)
        let alternatives = generateAlternatives(for: request)

        return Draft(
            content: content,
            subject: subject,
            alternatives: alternatives,
            confidence: calculateConfidence(for: request)
        )
    }

    /// Generate multiple draft variations
    public func generateDrafts(_ request: DraftRequest, count: Int = 3) async throws -> [Draft] {
        var drafts: [Draft] = []
        let tones: [Tone] = [request.tone, .friendly, .professional].prefix(count).map { $0 }

        for (index, tone) in tones.enumerated() {
            var modifiedRequest = request
            // Create variations by adjusting the approach
            let content = generateVariation(for: request, variation: index, tone: tone)
            let draft = Draft(
                content: content,
                subject: generateSubject(for: request),
                alternatives: [],
                confidence: calculateConfidence(for: request) - Double(index) * 0.1
            )
            drafts.append(draft)
        }

        return drafts
    }

    // MARK: - Quick Commands

    /// Process a quick command shorthand
    public func processQuickCommand(_ command: String, context: String?) async throws -> Draft {
        let parsed = parseQuickCommand(command)
        let request = DraftRequest(
            type: parsed.type,
            context: context,
            intent: parsed.intent,
            tone: parsed.tone
        )
        return try await generateDraft(request)
    }

    private func parseQuickCommand(_ command: String) -> (type: DraftType, intent: String, tone: Tone) {
        let lowercased = command.lowercased()

        // Reply patterns
        if lowercased.starts(with: "reply") {
            if lowercased.contains("yes") {
                return (.emailReply, "Accept/confirm", .friendly)
            } else if lowercased.contains("no") || lowercased.contains("decline") {
                return (.emailReply, "Decline politely", .professional)
            } else if lowercased.contains("later") || lowercased.contains("next week") {
                return (.emailReply, "Postpone/reschedule", .professional)
            }
        }

        // Generic
        return (.emailReply, command, .professional)
    }

    // MARK: - Learning

    /// Record user edits to learn from
    public func recordEdit(request: DraftRequest, original: String, edited: String) {
        let entry = DraftHistoryEntry(
            request: request,
            originalDraft: original,
            finalDraft: edited,
            wasEdited: original != edited,
            date: Date()
        )
        draftHistory.append(entry)

        // Keep history limited
        if draftHistory.count > 100 {
            draftHistory.removeFirst()
        }
    }

    /// Update writing style preference
    public func setWritingStyle(_ style: WritingStyle) {
        userWritingStyle = style
    }

    /// Get current writing style
    public func getWritingStyle() -> WritingStyle {
        return userWritingStyle
    }

    // MARK: - Private Helpers

    private func generateContent(for request: DraftRequest) -> String {
        let greeting = generateGreeting(for: request)
        let body = generateBody(for: request)
        let closing = generateClosing(for: request)

        return [greeting, body, closing].compactMap { $0 }.joined(separator: "\n\n")
    }

    private func generateGreeting(for request: DraftRequest) -> String? {
        guard request.type == .emailReply || request.type == .emailNew else {
            return nil
        }

        let recipient = request.recipient ?? "there"
        switch request.tone {
        case .friendly:
            return "Hi \(recipient),"
        case .formal:
            return "Dear \(recipient),"
        case .professional:
            return "Hello \(recipient),"
        case .casual:
            return "Hey \(recipient),"
        case .urgent:
            return "Hi \(recipient),"
        case .neutral:
            return "Hello \(recipient),"
        case .apologetic:
            return "Dear \(recipient),"
        case .enthusiastic:
            return "Hi \(recipient)!"
        }
    }

    private func generateBody(for request: DraftRequest) -> String {
        let intent = request.intent.lowercased()

        // Template responses based on intent
        if intent.contains("accept") || intent.contains("yes") || intent.contains("confirm") {
            return "Thank you for reaching out. I'd be happy to confirm. Please let me know if you need anything else."
        } else if intent.contains("decline") || intent.contains("no") {
            return "Thank you for thinking of me. Unfortunately, I won't be able to participate at this time. I appreciate your understanding."
        } else if intent.contains("reschedule") || intent.contains("postpone") || intent.contains("later") {
            return "Thank you for your message. Would it be possible to reschedule to next week? I have more availability then and want to give this the attention it deserves."
        } else if intent.contains("follow up") || intent.contains("check") {
            return "I wanted to follow up on our previous conversation. Please let me know if you have any updates or if there's anything I can help with."
        } else if intent.contains("thank") {
            return "Thank you so much for your help with this. I really appreciate your time and effort."
        } else if intent.contains("question") || intent.contains("ask") {
            return "I hope this message finds you well. I had a quick question I was hoping you could help with."
        }

        // Default
        return "Thank you for your message. \(request.intent)"
    }

    private func generateClosing(for request: DraftRequest) -> String? {
        guard request.type == .emailReply || request.type == .emailNew else {
            return nil
        }

        switch request.tone {
        case .friendly:
            return "Best,\n[Your Name]"
        case .formal:
            return "Sincerely,\n[Your Name]"
        case .professional:
            return "Best regards,\n[Your Name]"
        case .casual:
            return "Thanks!\n[Your Name]"
        case .urgent:
            return "Thanks,\n[Your Name]"
        case .neutral:
            return "Regards,\n[Your Name]"
        case .apologetic:
            return "Apologies again,\n[Your Name]"
        case .enthusiastic:
            return "Looking forward to it!\n[Your Name]"
        }
    }

    private func generateSubject(for request: DraftRequest) -> String? {
        guard request.type == .emailNew else { return nil }

        let intent = request.intent.lowercased()

        if intent.contains("meeting") {
            return "Meeting Request"
        } else if intent.contains("follow up") {
            return "Following Up"
        } else if intent.contains("question") {
            return "Quick Question"
        } else if intent.contains("update") {
            return "Update"
        }

        return "Re: Your Message"
    }

    private func generateAlternatives(for request: DraftRequest) -> [String] {
        // Generate 2 shorter/longer alternatives
        return [
            "Thank you! I'll take care of it.",
            "Thanks for reaching out. I'll follow up soon with more details."
        ]
    }

    private func generateVariation(for request: DraftRequest, variation: Int, tone: Tone) -> String {
        var modifiedRequest = DraftRequest(
            type: request.type,
            context: request.context,
            recipient: request.recipient,
            intent: request.intent,
            tone: tone,
            maxLength: request.maxLength
        )
        return generateContent(for: modifiedRequest)
    }

    private func calculateConfidence(for request: DraftRequest) -> Double {
        var confidence = 0.8

        // Increase confidence with more context
        if request.context != nil {
            confidence += 0.1
        }

        if request.recipient != nil {
            confidence += 0.05
        }

        return min(1.0, confidence)
    }
}
