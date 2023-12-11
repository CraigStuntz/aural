import XCTest

@testable import aural

class AudioUnitConfigTests: XCTestCase {
  func testToDictionaryKey_static() {
    let manufacturer = "Orange"
    let name = "My Cool Instrument"
    let typeName = "Music Device"
    let expected = "Orange\tMy Cool Instrument\tMusic Device"
    let actual = AudioUnitConfig.toDictionaryKey(
      manufacturer: manufacturer,
      name: name,
      typeName: typeName
    )

    XCTAssertEqual(expected, actual, "Incorrect dictionary key for static method")
  }
}
