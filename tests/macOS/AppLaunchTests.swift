import XCTest
@testable import Jarvis_macOS

/// Tests for macOS app launch
final class AppLaunchTests: XCTestCase {

    /// Verify macOS platform identifier
    func testPlatformIdentifier() {
        XCTAssertEqual(macOSPlatform.platform, "macOS")
    }

    /// Verify app can be referenced
    func testAppReference() {
        // This test passes if the app module can be imported
        XCTAssertTrue(true, "macOS app module imported successfully")
    }
}
