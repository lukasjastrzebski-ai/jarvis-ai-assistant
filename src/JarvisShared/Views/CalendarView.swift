import SwiftUI
import JarvisCore

/// Calendar view for schedule management
public struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedDate = Date()

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                // Calendar picker
                Section {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .onChange(of: selectedDate) { _, newValue in
                        Task {
                            await viewModel.loadEvents(for: newValue)
                        }
                    }
                }

                // Connected Calendars
                Section("Calendars") {
                    ForEach(viewModel.calendars, id: \.id) { calendar in
                        HStack {
                            Circle()
                                .fill(Color(hex: calendar.color) ?? .blue)
                                .frame(width: 12, height: 12)
                            Text(calendar.name)
                            Spacer()
                            Text(calendar.accountType.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Events for selected date
                Section("Events for \(viewModel.formatDate(selectedDate))") {
                    if viewModel.eventsForDate.isEmpty {
                        Text("No events")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.eventsForDate, id: \.id) { event in
                            EventRow(event: event, formatTime: viewModel.formatTime)
                        }
                    }
                }

                // Upcoming Events
                Section("Upcoming") {
                    if viewModel.upcomingEvents.isEmpty {
                        Text("No upcoming events")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.upcomingEvents, id: \.id) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                HStack {
                                    Text(viewModel.formatDateTime(event.startDate))
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
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
            .refreshable {
                await viewModel.refresh()
            }
        }
        .task {
            await viewModel.loadData()
            await viewModel.loadEvents(for: selectedDate)
        }
    }
}

struct EventRow: View {
    let event: CalendarEvent
    let formatTime: (Date) -> String

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(event.calendarId == "work-calendar" ? Color.blue : Color.green)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)

                HStack {
                    Text("\(formatTime(event.startDate)) - \(formatTime(event.endDate))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let location = event.location {
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                if !event.attendees.isEmpty {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                        Text("\(event.attendees.count) attendees")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
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

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var calendars: [JarvisCore.Calendar] = []
    @Published var eventsForDate: [CalendarEvent] = []
    @Published var upcomingEvents: [CalendarEvent] = []
    @Published var isLoading = false

    private let container = ServiceContainer.shared

    func loadData() async {
        isLoading = true
        container.configure(useMockServices: true)

        calendars = await container.mockCalendarProvider.getCalendars()
        upcomingEvents = await container.mockCalendarProvider.getUpcomingEvents(limit: 5)

        isLoading = false
    }

    func loadEvents(for date: Date) async {
        eventsForDate = await container.mockCalendarProvider.getEventsForDay(date)
    }

    func refresh() async {
        await loadData()
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Helper extension for hex colors
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}

#Preview {
    CalendarView()
}
