import SwiftUI
import JarvisCore

/// View for daily planning
public struct DailyPlanView: View {
    @StateObject private var viewModel = DailyPlanViewModel()
    @State private var newOutcomeTitle = ""
    @State private var newOutcomeMinutes = 30
    @State private var newOutcomeUrgency: PlannedOutcome.UrgencyLevel = .medium

    public init() {}

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Today's Plan")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.large)
                #endif
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            viewModel.showingAddOutcome = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }

                    if viewModel.hasWarnings {
                        ToolbarItem(placement: .automatic) {
                            Button {
                                viewModel.showingWarnings = true
                            } label: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
                .task {
                    await viewModel.loadTodaysPlan()
                }
                .sheet(isPresented: $viewModel.showingAddOutcome) {
                    addOutcomeSheet
                }
                .sheet(isPresented: $viewModel.showingWarnings) {
                    warningsSheet
                }
                .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                    Button("OK") {
                        viewModel.dismissError()
                    }
                } message: {
                    Text(viewModel.error ?? "")
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Planning your day...")
        } else if let plan = viewModel.currentPlan {
            planContent(plan)
        } else {
            emptyState
        }
    }

    private func planContent(_ plan: DailyPlan) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with progress
                planHeader(plan)

                // Calendar Events (if any)
                if !plan.calendarEvents.isEmpty {
                    calendarSection(plan.calendarEvents)
                }

                // Outcomes
                outcomesSection(plan.outcomes)

                // Accept Button (if draft)
                if plan.status == .draft {
                    acceptButton
                }
            }
            .padding()
        }
    }

    private func planHeader(_ plan: DailyPlan) -> some View {
        VStack(spacing: 12) {
            // Date
            Text(viewModel.formattedDate)
                .font(.headline)
                .foregroundStyle(.secondary)

            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.progressPercentage) / 100)
                    .stroke(progressColor(for: plan), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: viewModel.progressPercentage)

                VStack {
                    Text("\(viewModel.completedCount)/\(viewModel.totalCount)")
                        .font(.title2.bold())
                    Text("completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            // Time stats
            HStack(spacing: 24) {
                VStack {
                    Text(viewModel.plannedTimeFormatted)
                        .font(.subheadline.bold())
                    Text("Planned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack {
                    Text(viewModel.availableTimeFormatted)
                        .font(.subheadline.bold())
                    Text("Available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Overload warning
            if plan.isOverloaded {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Plan exceeds available time")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func progressColor(for plan: DailyPlan) -> Color {
        if plan.isOverloaded {
            return .orange
        }
        let percentage = viewModel.progressPercentage
        if percentage == 100 {
            return .green
        } else if percentage >= 50 {
            return .blue
        }
        return .blue.opacity(0.7)
    }

    private func calendarSection(_ events: [CalendarEventSummary]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendar")
                .font(.headline)

            ForEach(events) { event in
                HStack {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 4)

                    VStack(alignment: .leading) {
                        Text(event.title)
                            .font(.subheadline.bold())

                        if event.isAllDay {
                            Text("All day")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(formatEventTime(event))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func outcomesSection(_ outcomes: [PlannedOutcome]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("What Matters Today")
                    .font(.headline)
                Spacer()
                Text("\(outcomes.count) outcomes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(outcomes) { outcome in
                OutcomeRow(
                    outcome: outcome,
                    onComplete: {
                        Task {
                            await viewModel.completeOutcome(outcome)
                        }
                    },
                    onDelete: {
                        Task {
                            await viewModel.removeOutcome(outcome)
                        }
                    }
                )
            }
        }
    }

    private var acceptButton: some View {
        Button {
            Task {
                await viewModel.acceptPlan()
            }
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Accept Plan")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "sun.horizon.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Plan Your Day")
                .font(.title2.bold())

            Text("Generate a plan to focus on what matters most today.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.generatePlan()
                }
            } label: {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Generate Plan")
                }
                .font(.headline)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }

    private var addOutcomeSheet: some View {
        NavigationStack {
            Form {
                Section("Outcome") {
                    TextField("What do you want to accomplish?", text: $newOutcomeTitle)
                }

                Section("Estimated Time") {
                    Picker("Minutes", selection: $newOutcomeMinutes) {
                        ForEach([15, 30, 45, 60, 90, 120], id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Urgency") {
                    Picker("Urgency", selection: $newOutcomeUrgency) {
                        Text("Low").tag(PlannedOutcome.UrgencyLevel.low)
                        Text("Medium").tag(PlannedOutcome.UrgencyLevel.medium)
                        Text("High").tag(PlannedOutcome.UrgencyLevel.high)
                        Text("Critical").tag(PlannedOutcome.UrgencyLevel.critical)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Add Outcome")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showingAddOutcome = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addOutcome(
                                title: newOutcomeTitle,
                                estimatedMinutes: newOutcomeMinutes,
                                urgency: newOutcomeUrgency
                            )
                            newOutcomeTitle = ""
                        }
                    }
                    .disabled(newOutcomeTitle.isEmpty)
                }
            }
        }
    }

    private var warningsSheet: some View {
        NavigationStack {
            List {
                if let warnings = viewModel.currentPlan?.warnings {
                    ForEach(warnings) { warning in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: warningIcon(for: warning.type))
                                    .foregroundStyle(warningColor(for: warning.type))
                                Text(warning.message)
                                    .font(.subheadline.bold())
                            }

                            if let suggestion = warning.suggestion {
                                Text(suggestion)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Warnings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.showingWarnings = false
                    }
                }
            }
        }
    }

    private func formatEventTime(_ event: CalendarEventSummary) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: event.startTime)) - \(formatter.string(from: event.endTime))"
    }

    private func warningIcon(for type: PlanWarning.WarningType) -> String {
        switch type {
        case .overloaded:
            return "clock.badge.exclamationmark"
        case .noBreaks:
            return "cup.and.saucer"
        case .conflictingPriorities:
            return "arrow.triangle.2.circlepath"
        case .unrealisticEstimate:
            return "gauge.with.dots.needle.67percent"
        case .missingDeadline:
            return "calendar.badge.exclamationmark"
        }
    }

    private func warningColor(for type: PlanWarning.WarningType) -> Color {
        switch type {
        case .overloaded, .missingDeadline:
            return .orange
        case .noBreaks:
            return .yellow
        case .conflictingPriorities, .unrealisticEstimate:
            return .blue
        }
    }
}

/// Row view for a planned outcome
struct OutcomeRow: View {
    let outcome: PlannedOutcome
    let onComplete: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Complete button
            Button(action: onComplete) {
                Image(systemName: outcome.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(outcome.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(outcome.title)
                    .font(.subheadline.bold())
                    .strikethrough(outcome.isCompleted)
                    .foregroundStyle(outcome.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    // Time block
                    if let timeBlock = outcome.timeBlock {
                        Label(timeBlock.formattedTimeRange, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Duration
                    Text("\(outcome.estimatedMinutes) min")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Urgency badge
                    urgencyBadge
                }
            }

            Spacer()

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.gray.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(outcome.isCompleted ? Color.green.opacity(0.05) : Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var urgencyBadge: some View {
        let (color, text) = urgencyInfo
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var urgencyInfo: (Color, String) {
        switch outcome.urgency {
        case .critical:
            return (.red, "Critical")
        case .high:
            return (.orange, "High")
        case .medium:
            return (.blue, "Medium")
        case .low:
            return (.gray, "Low")
        }
    }
}

#Preview {
    DailyPlanView()
}
