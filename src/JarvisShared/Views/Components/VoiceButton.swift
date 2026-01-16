import SwiftUI
import JarvisCore

/// Voice activation button with visual feedback
public struct VoiceButton: View {
    @ObservedObject var viewModel: VoiceInteractionViewModel
    @State private var animationPhase: Double = 0

    public init(viewModel: VoiceInteractionViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Button {
            viewModel.toggleListening()
        } label: {
            ZStack {
                // Outer ring animation when listening
                if viewModel.state == .listening {
                    ForEach(0..<3) { ring in
                        Circle()
                            .stroke(Color.accentColor.opacity(0.3 - Double(ring) * 0.1), lineWidth: 2)
                            .frame(width: 60 + CGFloat(ring * 20), height: 60 + CGFloat(ring * 20))
                            .scaleEffect(1 + sin(animationPhase + Double(ring) * 0.5) * 0.1)
                    }
                }

                // Processing indicator
                if viewModel.state == .processing {
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.accentColor, lineWidth: 3)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(animationPhase * 30))
                }

                // Main button
                Circle()
                    .fill(buttonBackgroundColor)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

                // Microphone icon
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(iconColor)
            }
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.isAuthorized && viewModel.state == .idle)
        .onAppear {
            startAnimation()
        }
    }

    private var buttonBackgroundColor: Color {
        switch viewModel.state {
        case .listening:
            return .red
        case .processing:
            return .orange
        case .responding:
            return .green
        case .error:
            return .gray
        case .idle:
            return viewModel.isAuthorized ? .accentColor : .gray
        }
    }

    private var iconName: String {
        switch viewModel.state {
        case .listening:
            return "waveform"
        case .processing:
            return "ellipsis"
        case .responding:
            return "speaker.wave.2.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .idle:
            return viewModel.isAuthorized ? "mic.fill" : "mic.slash.fill"
        }
    }

    private var iconColor: Color {
        return .white
    }

    private func startAnimation() {
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
    }
}

/// Voice interaction overlay showing transcription and response
public struct VoiceInteractionOverlay: View {
    @ObservedObject var viewModel: VoiceInteractionViewModel

    public init(viewModel: VoiceInteractionViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // Transcription display
            if !viewModel.transcribedText.isEmpty {
                VStack(spacing: 8) {
                    Text("You said:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(viewModel.transcribedText)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Response display
            if !viewModel.responseText.isEmpty {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                        Text("Jarvis")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.secondary)

                    Text(viewModel.responseText)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(12)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Voice button
            VoiceButton(viewModel: viewModel)
                .padding(.bottom, 40)

            // State indicator
            Text(stateText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 20)
        }
        .padding()
        .animation(.easeInOut, value: viewModel.state)
        .animation(.easeInOut, value: viewModel.transcribedText)
        .animation(.easeInOut, value: viewModel.responseText)
    }

    private var stateText: String {
        switch viewModel.state {
        case .idle:
            return viewModel.isAuthorized ? "Tap to speak" : "Voice not authorized"
        case .listening:
            return "Listening..."
        case .processing:
            return "Processing..."
        case .responding:
            return "Done"
        case .error(let message):
            return message
        }
    }
}

/// Confirmation dialog for risky voice commands
public struct VoiceConfirmationDialog: View {
    @ObservedObject var viewModel: VoiceInteractionViewModel

    public init(viewModel: VoiceInteractionViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Command summary
            if let command = viewModel.currentCommand {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)

                    Text("Confirm Action")
                        .font(.headline)

                    Text(confirmationText(for: command))
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }

            // Action buttons
            HStack(spacing: 20) {
                Button(role: .cancel) {
                    viewModel.cancelCommand()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.confirmCommand()
                } label: {
                    Text("Confirm")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .background(.ultraThickMaterial)
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding(.horizontal, 40)
    }

    private func confirmationText(for command: VoiceCommand) -> String {
        switch command.type {
        case .sendEmail:
            let recipient = command.parameters["recipient"] ?? "the recipient"
            return "Send email to \(recipient)?"
        case .replyEmail:
            return "Send this reply?"
        case .scheduleMeeting:
            let attendee = command.parameters["attendee"] ?? "attendees"
            return "Schedule meeting with \(attendee)?"
        default:
            return "Execute this action?"
        }
    }
}

#Preview {
    let voiceService = VoiceService()
    let viewModel = VoiceInteractionViewModel(voiceService: voiceService)

    return VStack {
        Spacer()
        VoiceInteractionOverlay(viewModel: viewModel)
    }
}
