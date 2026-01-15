import SwiftUI

/// Sidebar-based navigation for macOS
public struct SidebarNavigation: View {
    @State private var selectedTab: JarvisTab? = .inbox

    public init() {}

    public var body: some View {
        NavigationSplitView {
            List(JarvisTab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationTitle("Jarvis")
        } detail: {
            if let tab = selectedTab {
                switch tab {
                case .inbox:
                    InboxView()
                case .today:
                    TodayView()
                case .calendar:
                    CalendarView()
                case .settings:
                    SettingsView()
                }
            } else {
                Text("Select a section")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    SidebarNavigation()
}
