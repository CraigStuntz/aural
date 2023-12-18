import XCTest

@testable import aural

class VersionsTests: XCTestCase {
  func test_compatible() {
    XCTAssertFalse(Version.compatible(version1: nil, version2: nil))
    XCTAssertFalse(Version.compatible(version1: nil, version2: ""))
    XCTAssertFalse(Version.compatible(version1: "", version2: nil))
    XCTAssertTrue(Version.compatible(version1: "1", version2: "1.0"))
    XCTAssertTrue(Version.compatible(version1: "10", version2: "1"))
  }

  func test_cleanupVersion() {
    XCTAssertEqual("1.1.0", Version.cleanUp(versionAsRead: "1_1_0"))
  }
}
