import AVFoundation
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

class AudioUnitConfigsTests: XCTestCase {
  func testSubscript() {
    let configs = AudioUnitConfigs()
    let components = AudioUnitComponents.components(
      filter: Filter(filterType: .name, name: "AUMIDISynth"))

    XCTAssertEqual(1, components.count)
    let component = components.first!

    let auMidiSynth = configs[component]

    XCTAssertNotNil(auMidiSynth)
  }
}
