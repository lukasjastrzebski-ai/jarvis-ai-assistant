import SwiftUI
import JarvisCore

/// Row view for an inbox item
public struct InboxItemRow: View {
    let item: Item
    let isSelected: Bool
    let onSelect: () -> Void
    let onQuickAction: (QuickAction) -> Void

    @State private var showQuickActions = false

    public init(
        item: Item,
        isSelected: Bool = false,
        onSelect: @escaping () -> Void = {},
        onQuickAction: @escaping (QuickAction) -> Void = { _ in }
    ) {
        self.item = item
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onQuickAction = onQuickAction
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Source icon
                sourceIcon
                    .foregroundStyle(sourceColor)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Title row
                    HStack {
                        Text(item.title)
                            .font(.headline)
                            .lineLimit(1)

                        Spacer()

                        // Priority indicator
                        if item.priority >= .high {
                            priorityBadge
                        }
                    }

                    // Subtitle row
                    HStack {
                        if let sourceType = item.sourceType {
                            Text(sourceType.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if item.content != nil {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(item.content ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    // Metadata row
                    HStack {
                        // Timestamp
                        Text(relativeTime)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        // Due date if exists
                        if let dueDate = item.dueDate {
                            Text("•")
                                .foregroundStyle(.tertiary)
                            HStack(spacing: 2) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                Text(formatDueDate(dueDate))
                                    .font(.caption2)
                            }
                            .foregroundStyle(dueDateColor(dueDate))
                        }

                        // Tags
                        if !item.tags.isEmpty {
                            Text("•")
                                .foregroundStyle(.tertiary)
                            HStack(spacing: 4) {
                                ForEach(item.tags.prefix(2), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.quaternary)
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
            }

            // Quick actions (expandable)
            if showQuickActions {
                QuickActionsBar(item: item, onAction: onQuickAction)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showQuickActions.toggle()
            }
        }
        .onLongPressGesture {
            onSelect()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onQuickAction(.archive)
            } label: {
                Label("Archive", systemImage: "archivebox")
            }

            Button {
                onQuickAction(.snooze)
            } label: {
                Label("Snooze", systemImage: "clock")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onQuickAction(.complete)
            } label: {
                Label("Complete", systemImage: "checkmark.circle")
            }
            .tint(.green)

            Button {
                onQuickAction(.moveToToday)
            } label: {
                Label("Today", systemImage: "sun.max")
            }
            .tint(.blue)
        }
    }

    // MARK: - Subviews

    private var sourceIcon: some View {
        Image(systemName: iconForSource)
            .font(.title2)
            .frame(width: 32, height: 32)
    }

    private var iconForSource: String {
        switch item.sourceType {
        case .email: return "envelope.fill"
        case .calendar: return "calendar"
        case .siri: return "waveform"
        case .shortcut: return "square.stack.fill"
        case .api: return "cloud.fill"
        case .manual, .none: return "doc.fill"
        }
    }

    private var sourceColor: Color {
        switch item.sourceType {
        case .email: return .blue
        case .calendar: return .red
        case .siri: return .purple
        case .shortcut: return .orange
        case .api: return .green
        case .manual, .none: return .gray
        }
    }

    private var priorityBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: item.priority == .urgent ? "exclamationmark.2" : "exclamationmark")
                .font(.caption)
            if item.priority == .urgent {
                Text("Urgent")
                    .font(.caption)
            }
        }
        .foregroundStyle(item.priority == .urgent ? .red : .orange)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(item.priority == .urgent ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(4)
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.createdAt, relativeTo: Date())
    }

    private func formatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }

    private func dueDateColor(_ date: Date) -> Color {
        let calendar = Calendar.current
        if date < Date() {
            return .red // Overdue
        } else if calendar.isDateInToday(date) {
            return .orange
        } else {
            return .secondary
        }
    }
}

/// Quick action types
public enum QuickAction: String, CaseIterable {
    case reply = "Reply"
    case archive = "Archive"
    case snooze = "Snooze"
    case addTask = "Add Task"
    case delegate = "Delegate"
    case complete = "Complete"
    case moveToToday = "Move to Today"
    case delete = "Delete"

    public var icon: String {
        switch self {
        case .reply: return "arrowshape.turn.up.left"
        case .archive: return "archivebox"
        case .snooze: return "clock"
        case .addTask: return "plus.circle"
        case .delegate: return "person.badge.plus"
        case .complete: return "checkmark.circle"
        case .moveToToday: return "sun.max"
        case .delete: return "trash"
        }
    }

    public var color: Color {
        switch self {
        case .reply: return .blue
        case .archive: return .gray
        case .snooze: return .orange
        case .addTask: return .green
        case .delegate: return .purple
        case .complete: return .green
        case .moveToToday: return .blue
        case .delete: return .red
        }
    }
}

/// Quick actions bar for an item
public struct QuickActionsBar: View {
    let item: Item
    let onAction: (QuickAction) -> Void

    private var availableActions: [QuickAction] {
        var actions: [QuickAction] = []

        // Email-specific actions
        if item.sourceType == .email {
            actions.append(.reply)
        }

        // Common actions
        actions.append(contentsOf: [.archive, .snooze, .addTask])

        // Task-specific
        if item.itemType == .task {
            actions.append(.complete)
        }

        return actions
    }

    public var body: some View {
        HStack(spacing: 16) {
            ForEach(availableActions, id: \.rawValue) { action in
                Button {
                    onAction(action)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: action.icon)
                            .font(.title3)
                        Text(action.rawValue)
                            .font(.caption2)
                    }
                    .foregroundStyle(action.color)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    List {
        InboxItemRow(
            item: Item(
                userId: UUID(),
                title: "Meeting notes from yesterday",
                content: "Here are the action items we discussed...",
                itemType: .task,
                priority: .high,
                dueDate: Date(),
                tags: ["work", "urgent"],
                sourceType: .email
            )
        ) {
            // Selection action
        } onQuickAction: { action in
            print("Action: \(action)")
        }

        InboxItemRow(
            item: Item(
                userId: UUID(),
                title: "Calendar: Team Standup",
                content: "Daily standup meeting",
                itemType: .event,
                sourceType: .calendar
            )
        )
    }
}
