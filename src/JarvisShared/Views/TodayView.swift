import SwiftUI
import JarvisCore

/// Today view showing daily planning and top outcomes
public struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                // Morning Briefing Section
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.greeting)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(viewModel.dateString)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "sun.max.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.yellow)
                    }
                    .padding(.vertical, 8)
                }

                // Today's Schedule
                Section("Today's Schedule") {
                    if viewModel.todaysEvents.isEmpty {
                        Text("No events today")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.todaysEvents, id: \.id) { event in
                            HStack {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(event.calendarId == "work-calendar" ? Color.blue : Color.green)
                                    .frame(width: 4)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title)
                                        .font(.headline)
                                    HStack {
                                        Text(viewModel.formatTime(event.startDate))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        if let location = event.location {
                                            Text("• \(location)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                }

                                Spacer()

                                if event.conferenceLink != nil {
                                    Image(systemName: "video.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Unread Emails
                Section("Unread Emails (\(viewModel.unreadEmails.count))") {
                    if viewModel.unreadEmails.isEmpty {
                        Text("No unread emails")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.unreadEmails.prefix(5), id: \.id) { email in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(email.from)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text(viewModel.formatRelativeTime(email.date))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(email.subject)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                // Tasks for Today
                Section("Tasks") {
                    if viewModel.todaysTasks.isEmpty {
                        Text("No tasks for today")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.todaysTasks, id: \.id) { task in
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundStyle(priorityColor(task.priority))
                                VStack(alignment: .leading) {
                                    Text(task.title)
                                        .font(.subheadline)
                                    if let content = task.content {
                                        Text(content)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                if task.priority == .urgent || task.priority == .high {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Today")
            .refreshable {
                await viewModel.refresh()
            }
        }
        .task {
            await viewModel.loadData()
        }
    }

    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .urgent: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .gray
        }
    }
}

@MainActor
class TodayViewModel: ObservableObject {
    @Published var todaysEvents: [CalendarEvent] = []
    @Published var unreadEmails: [Email] = []
    @Published var todaysTasks: [Item] = []
    @Published var isLoading = false

    private let container = ServiceContainer.shared
    private let sampleData = SampleDataGenerator.shared

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good Morning"
        } else if hour < 17 {
            return "Good Afternoon"
        } else {
            return "Good Evening"
        }
    }

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    func loadData() async {
        isLoading = true

        // Configure mock services
        container.configure(useMockServices: true)

        // Load calendar events
        todaysEvents = await container.mockCalendarProvider.getTodaysEvents()

        // Load emails
        let accounts = await container.mockEmailProvider.getAccounts()
        if let account = accounts.first {
            unreadEmails = await container.mockEmailProvider.getUnreadEmails(for: account.id)
        }

        // Load tasks from sample data
        let userId = UUID()
        todaysTasks = sampleData.generateSampleItems(userId: userId)
            .filter { $0.priority == .high || $0.priority == .urgent }

        isLoading = false
    }

    func refresh() async {
        await loadData()
    }
}

#Preview {
    TodayView()
}
