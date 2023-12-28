import XCTest

@testable import aural

class VersionsTests: XCTestCase {
  func test_compatible() {
    XCTAssertFalse(Version.compatible(latestVersion: "", existingVersion: "1"))
    XCTAssertFalse(Version.compatible(latestVersion: "1", existingVersion: ""))
    XCTAssertFalse(Version.compatible(latestVersion: "1.0.1", existingVersion: "1.0"))
    XCTAssertFalse(Version.compatible(latestVersion: "10", existingVersion: "1"))

    XCTAssertTrue(Version.compatible(latestVersion: "1.0", existingVersion: "1.0"))
    XCTAssertTrue(Version.compatible(latestVersion: "1.0.1.1234", existingVersion: "1.0.1"))
    XCTAssertTrue(Version.compatible(latestVersion: "1.0.1", existingVersion: "1.0.1.1234"))
  }

  func test_fromInt() {
    XCTAssertEqual("2.1.4", Version.fromInt(131332))
    XCTAssertEqual("2.1.20", Version.fromInt(131348))
  }

  func test_cleanupVersion() {
    XCTAssertEqual("1.1.0", Version.cleanUp(versionAsRead: "1_1_0"))
  }

  func test_parseWithJMESPath() throws {
    let body = #"{"a": {"b": "1.2.3.4"}}"#
    let jmesPath = "a.b"

    let actual: String? = try Version.parseWithJMESPath(body, jmesPath)

    XCTAssertEqual("1.2.3.4", actual)
  }

  func test_parseWithJMESPath_invalid_body_should_return_nil() throws {
    let body = #"{"a": "foobar"}"#
    let jmesPath = "a.b"

    let actual: String? = try Version.parseWithJMESPath(body, jmesPath)

    XCTAssertNil(actual)
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
