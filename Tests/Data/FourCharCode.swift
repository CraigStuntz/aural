import Foundation
import Testing

@testable import aural

struct FourCharCodeTests {
  @Test func testToString() {
    let appl: FourCharCode = 1_634_758_764
    #expect("appl" == appl.toString())

    let sys: FourCharCode = 1_937_339_168
    #expect("sys " == sys.toString())
  }
}
