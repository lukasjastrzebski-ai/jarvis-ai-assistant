import XCTest
@testable import JarvisCore

/// Tests to verify the project setup and build configuration
final class SetupTests: XCTestCase {

    /// Verify that the JarvisCore module is accessible
    func testModuleImport() {
        // If this compiles, the module import works
        XCTAssertTrue(true, "JarvisCore module imported successfully")
    }

    /// Verify version information is available
    func testVersionInfo() {
        XCTAssertFalse(Jarvis.version.isEmpty, "Version should not be empty")
        XCTAssertFalse(Jarvis.buildDate.isEmpty, "Build date should not be empty")
    }

    /// Verify build configuration
    func testBuildConfiguration() {
        // This test passes if the project builds successfully
        #if DEBUG
        XCTAssertTrue(true, "Debug configuration")
        #else
        XCTAssertTrue(true, "Release configuration")
        #endif
    }
}
