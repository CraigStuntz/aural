import AVFoundation
import Testing

@testable import aural

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
  @Test func testSubscript() throws {
    let configs = AudioUnitConfigs()
    let components = AudioUnitComponents.components(
      maybeFilter: Filter(filterType: .name, name: "AUMIDISynth"))

    #expect(1 == components.count)
    let component = try #require(components.first)

    #expect(configs[component] != nil)
  }

  @Test func testEncodeAsPlist() throws {
    let configs = AudioUnitConfigs()
    let components = AudioUnitComponents.components(
      maybeFilter: Filter(filterType: .name, name: "AUMIDISynth"))
    let actual = try configs.toPlist(components)
    #expect(actual.count > 0)
  }

  @Test func testVersionOverrides() throws {
    let configs = AudioUnitConfigs()
    let ottConfigs = configs.configs.filter { $0.manufacturer == "XFER" && $0.name == "XfTT" }
    let synthMaster2Configs = configs.configs.filter {
      $0.manufacturer == "k331" && ($0.name == "Sm2f" || $0.name == "Sm2i")
    }

    #expect(ottConfigs.count == 2)
    #expect(ottConfigs.allSatisfy { $0.versionOverrides == ["1.3.7": "1.37"] })
    #expect(synthMaster2Configs.count == 2)
    #expect(
      synthMaster2Configs.allSatisfy {
        $0.versionFixed == "2.9.18" && $0.versionOverrides == ["2.9.10": "2.9.18"]
      })
  }
}
