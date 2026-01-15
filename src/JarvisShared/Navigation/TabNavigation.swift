import SwiftUI

/// Tab-based navigation for iOS (and compact macOS)
public struct TabNavigation: View {
    @State private var selectedTab: JarvisTab = .inbox

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            InboxView()
                .tabItem {
                    Label(JarvisTab.inbox.rawValue, systemImage: JarvisTab.inbox.icon)
                }
                .tag(JarvisTab.inbox)

            TodayView()
                .tabItem {
                    Label(JarvisTab.today.rawValue, systemImage: JarvisTab.today.icon)
                }
                .tag(JarvisTab.today)

            CalendarView()
                .tabItem {
                    Label(JarvisTab.calendar.rawValue, systemImage: JarvisTab.calendar.icon)
                }
                .tag(JarvisTab.calendar)

            SettingsView()
                .tabItem {
                    Label(JarvisTab.settings.rawValue, systemImage: JarvisTab.settings.icon)
                }
                .tag(JarvisTab.settings)
        }
    }
}

#Preview {
    TabNavigation()
}
