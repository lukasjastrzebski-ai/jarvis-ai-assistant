import SwiftUI
import JarvisShared

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
