import SwiftUI

/// Unified inbox view showing all incoming items
public struct InboxView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Text("No items in inbox")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Inbox")
        }
    }
}

#Preview {
    InboxView()
}
