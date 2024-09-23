import AVFoundation
import Testing
@testable import aural

struct AudioUnitComponentsTests {
  @Test func testComponentsAtLeastSomeExistOnSystem() {
    let components = AudioUnitComponents.components(maybeFilter: nil)

    #expect(
      components.count > 0,
      "Other tests will fail if there are no Audio Units installed on the system")
  }

  @Test func testComponentsFilterManufacturer() {
    let components = AudioUnitComponents.components(
      maybeFilter: Filter(filterType: .manufacturer, name: "Apple"))

    #expect(components.count > 0, "There should be lots of Apple AUs")
  }

  @Test func testComponentsFilterName() throws {
    let components = AudioUnitComponents.components(
      maybeFilter: Filter(filterType: .name, name: "AUConverter"))

    #expect(1 == components.count, "There should only be one component named AUConverter")
    let firstComponent = try #require(components.first)
    #expect(
      "AUConverter" == firstComponent.name, "The component should be named 'AUConverter'")
  }

  @Test func testComponentsFilterType() {
    let components = AudioUnitComponents.components(
      maybeFilter: Filter(filterType: .type, name: "Music Device"))

    #expect(components.count > 0, "Music Device AUs should exist.")
  }
}
