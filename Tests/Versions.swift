import XCTest

@testable import aural

class VersionsTests: XCTestCase {
  func test_compatible() {
    XCTAssertFalse(Versions.compatible(version1: nil, version2: nil))
    XCTAssertFalse(Versions.compatible(version1: nil, version2: ""))
    XCTAssertFalse(Versions.compatible(version1: "", version2: nil))
    XCTAssertTrue(Versions.compatible(version1: "1", version2: "1.0"))
    XCTAssertTrue(Versions.compatible(version1: "10", version2: "1"))
  }
}
