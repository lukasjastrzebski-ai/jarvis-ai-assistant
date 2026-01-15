import SwiftUI

/// Calendar view for schedule management
public struct CalendarView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Text("Calendar integration coming soon")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Calendar")
        }
    }
}

#Preview {
    CalendarView()
}
