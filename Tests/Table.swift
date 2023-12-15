import XCTest

@testable import aural

class TableTests: XCTestCase {
  let headers = ["header1", "h2"]
  let data = [
    ["data1", "d2"],
    ["d1", "data2 "],
  ]

  func test_init() {
    let table = Table(headers: self.headers, data: self.data)

    XCTAssertEqual(table.maxesByColumn.count, 2, "maxesByColumn.count should equal 2")
    XCTAssertEqual(table.maxesByColumn[0], 7, "maxesByColumn[0] should equal 7")
    XCTAssertEqual(table.maxesByColumn[1], 6, "maxesByColumn[1] should equal 6")
  }

  func test_init_without_headers() {
    let table = Table(headers: [], data: self.data)

    XCTAssertEqual(table.maxesByColumn.count, 2, "maxesByColumn.count should equal 2")
    XCTAssertEqual(table.maxesByColumn[0], 5, "maxesByColumn[0] should equal 5")
    XCTAssertEqual(table.maxesByColumn[1], 6, "maxesByColumn[1] should equal 6")
  }

  func test_toPadded() {
    let table = Table(headers: self.headers, data: self.data)
    let padded = table.toPadded()

    XCTAssertEqual(padded.count, 4, "There should be 4 rows in padded")
    XCTAssertEqual(padded[0][0].count, 7, "The first column of padded should be 7 characters wide")
    XCTAssertEqual(padded[0][1].count, 6, "The second column of padded should be 6 characters wide")
  }

  func test_toPadded_without_headers() {
    let table = Table(headers: [], data: self.data)
    let padded = table.toPadded()

    XCTAssertEqual(padded.count, 2, "There should be 2 rows in padded")
    XCTAssertEqual(padded[0][0].count, 5, "The first column of padded should be 5 characters wide")
    XCTAssertEqual(padded[0][1].count, 6, "The second column of padded should be 6 characters wide")
  }
}
