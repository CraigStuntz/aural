import XCTest

@testable import aural

class RetrieveCurrentVersionTests: XCTestCase {
  func test_cleanupVersion() {
    XCTAssertEqual("1.1.0", HTTPVersionRetriever.cleanupVersion(versionAsRead: "1_1_0"))
  }
}
