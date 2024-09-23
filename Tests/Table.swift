import Testing
@testable import aural

struct TableTests {
  let headers = ["header1", "h2"]
  let data = [
    ["data1", "d2"],
    ["d1", "data2 "],
  ]

  @Test func initialize() {
    let table = Table(headers: self.headers, data: self.data)

    #expect(table.maxesByColumn.count == 2, "maxesByColumn.count should equal 2")
    #expect(table.maxesByColumn[0] == 7, "maxesByColumn[0] should equal 7")
    #expect(table.maxesByColumn[1] == 6, "maxesByColumn[1] should equal 6")
  }

  @Test func initWithoutHeaders() {
    let table = Table(headers: [], data: self.data)

    #expect(table.maxesByColumn.count == 2, "maxesByColumn.count should equal 2")
    #expect(table.maxesByColumn[0] == 5, "maxesByColumn[0] should equal 5")
    #expect(table.maxesByColumn[1] == 6, "maxesByColumn[1] should equal 6")
  }

  @Test func toPadded() {
    let table = Table(headers: self.headers, data: self.data)
    let padded = table.toPadded()

    #expect(padded.count == 4, "There should be 4 rows in padded")
    #expect(padded[0][0].count == 7, "The first column of padded should be 7 characters wide")
    #expect(padded[0][1].count == 6, "The second column of padded should be 6 characters wide")
  }

  @Test func toPaddedWithoutHeaders() {
    let table = Table(headers: [], data: self.data)
    let padded = table.toPadded()

    #expect(padded.count == 2, "There should be 2 rows in padded")
    #expect(padded[0][0].count == 5, "The first column of padded should be 5 characters wide")
    #expect(padded[0][1].count == 6, "The second column of padded should be 6 characters wide")
  }
}
