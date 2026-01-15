import SwiftUI

/// Adaptive navigation that uses tabs on iOS and sidebar on macOS
public struct AdaptiveNavigation: View {
    #if os(iOS)
    public init() {}

    public var body: some View {
        TabNavigation()
    }
    #else
    public init() {}

    public var body: some View {
        SidebarNavigation()
    }
    #endif
}

#Preview {
    AdaptiveNavigation()
}
