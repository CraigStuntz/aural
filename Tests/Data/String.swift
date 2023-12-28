import XCTest

@testable import aural

class StringTests: XCTestCase {
  func test_toFourCharCode() {
    let appl: FourCharCode = 1_634_758_764
    XCTAssertEqual(appl, "appl".toFourCharCode(), "Failed for appl")

    let sys: FourCharCode = 1_937_339_168
    XCTAssertEqual(sys, "sys ".toFourCharCode(), "Failed for sys ")

    let unknown: FourCharCode = 0
    XCTAssertEqual(unknown, "".toFourCharCode(), "Failed for empty string")
  }

  func test_roundtripAll() {
    let components = AudioUnitComponents.components(maybeFilter: nil)
    let componentCodes: Set<FourCharCode> = Set(
      components.map {
        [
          $0.audioComponentDescription.componentType,
          $0.audioComponentDescription.componentSubType,
          $0.audioComponentDescription.componentManufacturer,
        ]
      }.joined())

    XCTAssertFalse(componentCodes.isEmpty)
    for fourCharCode in componentCodes {
      let s = fourCharCode.toString()
      let c = s.toFourCharCode()
      let s2 = c.toString()
      XCTAssertEqual(s, s2, "Failed for \(fourCharCode)")
    }
  }
}
