import Testing

@testable import aural

struct VersionsTests {
  @Test func compatible() {
    #expect(!Version.compatible(latestVersion: "", existingVersion: "1"))
    #expect(!Version.compatible(latestVersion: "1", existingVersion: ""))
    #expect(!Version.compatible(latestVersion: "1.0.1", existingVersion: "1.0"))
    #expect(!Version.compatible(latestVersion: "10", existingVersion: "1"))

    #expect(Version.compatible(latestVersion: "1.0", existingVersion: "1.0"))
    #expect(Version.compatible(latestVersion: "1.0.1.1234", existingVersion: "1.0.1"))
    #expect(Version.compatible(latestVersion: "1.0.1", existingVersion: "1.0.1.1234"))
  }

  @Test func fromInt() {
    #expect("2.1.4" == Version.fromInt(131332))
    #expect("2.1.20" == Version.fromInt(131348))
  }

  @Test func cleanupVersion() {
    #expect("1.1.0" == Version.cleanUp(versionAsRead: "1_1_0"))
  }

  @Test func parseWithJMESPath() throws {
    let body = #"{"a": {"b": "1.2.3.4"}}"#
    let jmesPath = "a.b"

    let actual: String = try #require(try Version.parseWithJMESPath(body, jmesPath))

    #expect("1.2.3.4" == actual)
  }

  @Test func parseWithJMESPathInvalidBodyShouldReturnNil() throws {
    let body = #"{"a": "foobar"}"#
    let jmesPath = "a.b"

    let actual: String? = try Version.parseWithJMESPath(body, jmesPath)

    #expect(actual == nil)
  }

  @Test func parseWithRegex() throws {
    let body = """
      Filter_MS-20__1_0_2_3.pkg">Filter MS-20
      """
    let versionMatchRegex = """
      Filter_MS\\-20__(\\d*_\\d*_\\d*_\\d*)\\.pkg">Filter MS\\-20
      """
    let actual = try Version.parseWithRegex(body, versionMatchRegex)
    #expect("1.0.2.3" == actual)
  }

  @Test func parseWithRegexInvalidBodyShouldThrow() throws {
    let body = """
      blarf
      """
    let versionMatchRegex = """
      Filter_MS\\-20__(\\d*_\\d*_\\d*_\\d*)\\.pkg">Filter MS\\-20
      """
    
    #expect(throws: UpdateError.self) { try Version.parseWithRegex(body, versionMatchRegex) }
  }

  @Test func interleaveDots() {
    let versionAsRead = "147"

    let actual = Version.interleaveDots(versionAsRead: versionAsRead)

    #expect("1.4.7" == actual)
  }
}
