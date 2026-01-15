/// JarvisShared - Shared UI components for iOS and macOS
///
/// This module provides the shared SwiftUI views and navigation
/// used by both the iOS and macOS applications.

import SwiftUI
import JarvisCore

/// Main tabs/sections in the app
public enum JarvisTab: String, CaseIterable, Identifiable {
    case inbox = "Inbox"
    case today = "Today"
    case calendar = "Calendar"
    case settings = "Settings"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .inbox: return "tray.fill"
        case .today: return "sun.max.fill"
        case .calendar: return "calendar"
        case .settings: return "gearshape.fill"
        }
    }
}
