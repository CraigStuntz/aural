import XCTest

@testable import aural

class FiltersTests: XCTestCase {
  func testParseArgument() {
    let filter = Filter.parseArgument("manufacturer:Tomato")

    XCTAssertNotNil(filter)
    XCTAssertEqual(filter!.0, FilterType.manufacturer, "Incorrect manufacturer")
    XCTAssertEqual(filter!.1, "Tomato", "Incorrect manufacturer name")
  }

  func testParseArgument_malformed() {
    let filter = Filter.parseArgument("tomato")

    XCTAssertNil(filter)
  }

  func testParseArgument_with_invalid_filter_type() {
    let filter = Filter.parseArgument("foo:bar")

    XCTAssertNil(filter)
  }
}
