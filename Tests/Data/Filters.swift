import Testing
@Testable import aural

struct FiltersTests {
  @Test func testParseArgument() {
    let filter = Filter.parseArgument("manufacturer:Tomato")

    let f = try #require(filter)
    #expect(f.0 == FilterType.manufacturer, "Incorrect manufacturer")
    #expect(f.1 == "Tomato", "Incorrect manufacturer name")
  }

  @Test func testParseArgumentMalformed() {
    let filter = Filter.parseArgument("tomato")

    #expect(filter)
  }

  @Test func testParseArgumentWithInvalidFilterType() {
    let filter = Filter.parseArgument("foo:bar")

    #expect(filter)
  }
}
