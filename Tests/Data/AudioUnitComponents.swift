import AVFoundation
import XCTest

@testable import aural

class AudioUnitComponentsTests: XCTestCase {
  func testComponents_at_least_some_exist_on_system() {
    let components = AudioUnitComponents.components(filter: nil)

    XCTAssertGreaterThan(
      components.count, 0,
      "Other tests will fail if there are no Audio Units installed on the system")
  }

  func testComponents_filter_manufacturer() {
    let components = AudioUnitComponents.components(
      filter: Filter(filterType: .manufacturer, name: "Apple"))

    XCTAssertGreaterThan(components.count, 0, "There should be lots of Apple AUs")
  }

  func testComponents_filter_name() {
    let components = AudioUnitComponents.components(
      filter: Filter(filterType: .name, name: "AUConverter"))

    XCTAssertEqual(1, components.count, "There should only be one component named AUConverter")
    XCTAssertEqual(
      "AUConverter", components.first!.name, "The component should be named 'AUConverter'")
  }

  func testComponents_filter_type() {
    let components = AudioUnitComponents.components(
      filter: Filter(filterType: .type, name: "Music Device"))

    XCTAssertGreaterThan(components.count, 0, "Music Device AUs should exist.")
  }
}
