import SwiftUI
import JarvisCore

/// Activity log view showing all Jarvis actions
public struct ActivityLogView: View {
    @StateObject private var viewModel: ActivityLogViewModel
    @State private var showExportSheet = false
    @State private var exportData: Data?

    /// Initialize with dependencies
    public init(activityService: ActivityService, userId: UUID) {
        _viewModel = StateObject(wrappedValue: ActivityLogViewModel(
            activityService: activityService,
            userId: userId
        ))
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Activity")
                .toolbar {
                    toolbarContent
                }
                .refreshable {
                    await viewModel.refresh()
                }
                .sheet(isPresented: $viewModel.showActionDetail) {
                    if let action = viewModel.selectedAction {
                        ActionDetailView(action: action) {
                            viewModel.clearSelection()
                        }
                    }
                }
        }
        .task {
            await viewModel.loadActions()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.actions.isEmpty {
            loadingView
        } else if viewModel.actions.isEmpty {
            emptyView
        } else {
            actionsList
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading activity...")
                .foregroundStyle(.secondary)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Activity Yet")
                .font(.headline)

            Text("Your actions will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var actionsList: some View {
        List {
            // Error message
            if let error = viewModel.errorMessage {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.yellow)
                        Text(error)
                            .font(.caption)
                    }
                }
            }

            // Summary card
            if let summary = viewModel.summary {
                Section {
                    summaryCard(summary)
                }
            }

            // Filter chips
            Section {
                filterChips
            }

            // Grouped actions by date
            ForEach(viewModel.groupedActions, id: \.date) { group in
                Section {
                    ForEach(group.actions) { action in
                        ActionRow(action: action)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectAction(action)
                            }
                    }
                } header: {
                    Text(formatSectionDate(group.date))
                }
            }
        }
    }

    private func summaryCard(_ summary: ActivitySummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Summary")
                    .font(.headline)
                Spacer()
                Text("\(summary.totalActions) actions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                statBadge(count: summary.creates, label: "Created", icon: "plus.circle", color: .green)
                statBadge(count: summary.updates, label: "Updated", icon: "pencil", color: .blue)
                statBadge(count: summary.completes, label: "Completed", icon: "checkmark", color: .purple)
            }

            if let hour = summary.mostActiveHour {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                    Text("Most active at \(formatHour(hour))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func statBadge(count: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text("\(count)")
                    .font(.headline)
            }
            .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Date range picker
                Menu {
                    ForEach(ActivityDateRange.allCases) { range in
                        Button {
                            viewModel.dateRange = range
                            Task {
                                await viewModel.loadActions()
                            }
                        } label: {
                            if viewModel.dateRange == range {
                                Label(range.rawValue, systemImage: "checkmark")
                            } else {
                                Text(range.rawValue)
                            }
                        }
                    }
                } label: {
                    Label(viewModel.dateRange.rawValue, systemImage: "calendar")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.quaternary)
                        .cornerRadius(16)
                }

                Divider()
                    .frame(height: 20)

                // Type filters
                ForEach(ActivityFilter.allCases) { filter in
                    filterChip(for: filter)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func filterChip(for filter: ActivityFilter) -> some View {
        Button {
            viewModel.filterType = filter
        } label: {
            HStack(spacing: 4) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(viewModel.filterType == filter ? Color.accentColor : Color.gray.opacity(0.2))
            .foregroundStyle(viewModel.filterType == filter ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button {
                    exportData = viewModel.exportActions()
                    showExportSheet = true
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }

                Button {
                    Task {
                        await viewModel.refresh()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    // MARK: - Helpers

    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }
}

/// Row view for an action
public struct ActionRow: View {
    let action: Action

    public var body: some View {
        HStack(spacing: 12) {
            // Action type icon
            Image(systemName: iconForActionType)
                .font(.title3)
                .foregroundStyle(colorForActionType)
                .frame(width: 32, height: 32)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(action.description)
                    .font(.subheadline)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(action.actionType.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.tertiary)

                    Text(action.targetType.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(formatTime(action.timestamp))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var iconForActionType: String {
        switch action.actionType {
        case .create: return "plus.circle.fill"
        case .read: return "doc.text.fill"
        case .update: return "pencil.circle.fill"
        case .delete: return "trash.fill"
        case .complete: return "checkmark.circle.fill"
        case .uncomplete: return "arrow.uturn.backward.circle.fill"
        case .archive: return "archivebox.fill"
        case .restore: return "arrow.counterclockwise"
        case .schedule: return "calendar.badge.plus"
        case .reschedule: return "calendar.badge.clock"
        case .prioritize: return "exclamationmark.circle.fill"
        case .tag: return "tag.fill"
        case .untag: return "tag.slash.fill"
        case .view: return "eye.fill"
        case .search: return "magnifyingglass"
        case .filter: return "line.3.horizontal.decrease.circle.fill"
        case .sync: return "arrow.triangle.2.circlepath"
        case .login: return "person.badge.key.fill"
        case .logout: return "rectangle.portrait.and.arrow.right.fill"
        case .settingsChange: return "gearshape.fill"
        }
    }

    private var colorForActionType: Color {
        switch action.actionType {
        case .create: return .green
        case .read: return .gray
        case .update: return .blue
        case .delete: return .red
        case .complete: return .purple
        case .uncomplete: return .orange
        case .archive: return .brown
        case .restore: return .teal
        case .schedule, .reschedule: return .indigo
        case .prioritize: return .pink
        case .tag, .untag: return .mint
        case .view: return .gray
        case .search: return .orange
        case .filter: return .cyan
        case .sync: return .cyan
        case .login, .logout: return .blue
        case .settingsChange: return .gray
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

/// Detail view for a single action
public struct ActionDetailView: View {
    let action: Action
    let onDismiss: () -> Void

    public var body: some View {
        NavigationStack {
            List {
                // Basic info
                Section {
                    LabeledContent("Type", value: action.actionType.rawValue.capitalized)
                    LabeledContent("Target", value: action.targetType.rawValue.capitalized)
                    LabeledContent("Time", value: formatDateTime(action.timestamp))
                }

                // Description
                Section("Description") {
                    Text(action.description)
                }

                // Target details
                if let targetId = action.targetId {
                    Section("Target") {
                        LabeledContent("ID", value: targetId.uuidString)
                    }
                }

                // Metadata
                if !action.metadata.isEmpty {
                    Section("Details") {
                        ForEach(action.metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            LabeledContent(key.capitalized, value: value)
                        }
                    }
                }

                // Session info
                Section("Session") {
                    if let deviceId = action.deviceId {
                        LabeledContent("Device", value: deviceId)
                    }
                    if let sessionId = action.sessionId {
                        LabeledContent("Session", value: sessionId.uuidString.prefix(8).description)
                    }
                }
            }
            .navigationTitle("Action Detail")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDismiss)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    let storage = InMemoryActionStorage()
    let service = ActivityService(storage: storage)

    return ActivityLogView(activityService: service, userId: UUID())
}
