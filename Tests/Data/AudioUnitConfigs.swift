import AVFoundation
import Testing
@Testable import aural

struct AudioUnitConfigTests {
  @Test func testToDictionaryKeyStatic() {
    let manufacturer = "Orange"
    let name = "My Cool Instrument"
    let typeName = "Music Device"
    let expected = "Orange\tMy Cool Instrument\tMusic Device"

    let actual = AudioUnitConfig.toDictionaryKey(
      manufacturer: manufacturer,
      name: name,
      typeName: typeName
    )

    #expect(expected == actual, "Incorrect dictionary key for static method")
  }
}

struct AudioUnitConfigsTests {
  @Test func testSubscript() {
    let configs = AudioUnitConfigs()
    let components = AudioUnitComponents.components(
      maybeFilter: Filter(filterType: .name, name: "AUMIDISynth"))

    XCTAssertEqual(1, components.count)
    let component = try #require(components.first)

    let auMidiSynth = try #require(configs[component])

    #expect(auMidiSynth)
  }
}
