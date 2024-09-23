import Testing

@testable import aural

struct FiltersTests {
  @Test func testParseArgument() throws {
    let filter = Filter.parseArgument("manufacturer:Tomato")

    let f = try #require(filter)
    #expect(f.0 == FilterType.manufacturer, "Incorrect manufacturer")
    #expect(f.1 == "Tomato", "Incorrect manufacturer name")
  }

  @Test func testParseArgumentMalformed() throws {
    let filter = Filter.parseArgument("tomato")

    #expect(filter == nil)
  }

  @Test func testParseArgumentWithInvalidFilterType() throws {
    let filter = Filter.parseArgument("foo:bar")

    #expect(filter == nil)
  }
}
