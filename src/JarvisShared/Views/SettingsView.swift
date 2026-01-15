import SwiftUI
import JarvisCore

/// Settings view for app configuration
public struct SettingsView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    LabeledContent("Version", value: Jarvis.version)
                    LabeledContent("Build Date", value: Jarvis.buildDate)
                }
                Section("Integrations") {
                    Text("No integrations configured")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
