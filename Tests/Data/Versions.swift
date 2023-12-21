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

  func test_fromInt() {
    XCTAssertEqual("2.1.4", Version.fromInt(131332))
  }

  func test_cleanupVersion() {
    XCTAssertEqual("1.1.0", Version.cleanUp(versionAsRead: "1_1_0"))
  }

  func test_parseWithJMESPath() throws {
    let body = #"{"a": {"b": "1.2.3.4"}}"#
    let jmesPath = "a.b"

    XCTAssertEqual("1.2.3.4", try Version.parseWithJMESPath(body, jmesPath))
  }

  func test_parseWithJMESPath_invalid_body_should_return_nil() throws {
    let body = #"{"a": "foobar"}"#
    let jmesPath = "a.b"

    XCTAssertNil(try Version.parseWithJMESPath(body, jmesPath))
  }

  func test_parseWithRegex() throws {
    let body = """
      Filter_MS-20__1_0_2_3.pkg">Filter MS-20
      """
    let versionMatchRegex = """
      Filter_MS\\-20__(\\d*_\\d*_\\d*_\\d*)\\.pkg">Filter MS\\-20
      """
    XCTAssertEqual("1.0.2.3", try Version.parseWithRegex(body, versionMatchRegex))
  }

  func test_parseWithRegex_invalid_body_should_return_nil() throws {
    let body = """
      blarf
      """
    let versionMatchRegex = """
      Filter_MS\\-20__(\\d*_\\d*_\\d*_\\d*)\\.pkg">Filter MS\\-20
      """
    XCTAssertNil(try Version.parseWithRegex(body, versionMatchRegex))
  }
}
