import SwiftUI
import JarvisShared

/// Main entry point for the Jarvis application
/// Shared between iOS and macOS
@main
struct JarvisApp: App {
    var body: some Scene {
        WindowGroup {
            AdaptiveNavigation()
        }
        #if os(macOS)
        .windowStyle(.automatic)
        .defaultSize(width: 1000, height: 700)
        #endif
    }
}
