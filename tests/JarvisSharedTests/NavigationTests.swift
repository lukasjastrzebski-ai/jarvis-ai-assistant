import XCTest
@testable import JarvisShared

/// Tests for the shared navigation components
final class NavigationTests: XCTestCase {

    /// Verify all tabs are defined
    func testAllTabsDefined() {
        let tabs = JarvisTab.allCases
        XCTAssertEqual(tabs.count, 4, "Should have 4 tabs")
        XCTAssertTrue(tabs.contains(.inbox))
        XCTAssertTrue(tabs.contains(.today))
        XCTAssertTrue(tabs.contains(.calendar))
        XCTAssertTrue(tabs.contains(.settings))
    }

    /// Verify each tab has an icon
    func testTabIcons() {
        for tab in JarvisTab.allCases {
            XCTAssertFalse(tab.icon.isEmpty, "\(tab.rawValue) should have an icon")
        }
    }

    /// Verify tab identifiers are unique
    func testTabIdentifiers() {
        let ids = JarvisTab.allCases.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "Tab IDs should be unique")
    }
}
