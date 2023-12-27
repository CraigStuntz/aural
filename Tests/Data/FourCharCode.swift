import XCTest

@testable import aural

class FourCharCodeTests: XCTestCase {
  func testToString() {
    let appl: FourCharCode = 1_634_758_764
    XCTAssertEqual("appl", appl.toString())

    let sys: FourCharCode = 1_937_339_168
    XCTAssertEqual("sys ", sys.toString())
  }
}
