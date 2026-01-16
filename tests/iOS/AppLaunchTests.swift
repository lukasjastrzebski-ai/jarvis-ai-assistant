import XCTest
@testable import Jarvis_iOS

/// Tests for iOS app launch
final class AppLaunchTests: XCTestCase {

    /// Verify iOS platform identifier
    func testPlatformIdentifier() {
        XCTAssertEqual(iOSPlatform.platform, "iOS")
    }

    /// Verify app can be referenced
    func testAppReference() {
        // This test passes if the app module can be imported
        XCTAssertTrue(true, "iOS app module imported successfully")
    }
}
