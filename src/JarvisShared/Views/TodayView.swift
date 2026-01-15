import SwiftUI

/// Today view showing daily planning and top outcomes
public struct TodayView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("Top Outcomes") {
                    Text("No outcomes set")
                        .foregroundStyle(.secondary)
                }
                Section("Schedule") {
                    Text("No events today")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Today")
        }
    }
}

#Preview {
    TodayView()
}
