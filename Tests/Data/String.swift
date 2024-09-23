import Foundation
import Testing

@testable import aural

struct StringTests {
  @Test func toFourCharCode() {
    let appl: FourCharCode = 1_634_758_764
    #expect(appl == "appl".toFourCharCode(), "Failed for appl")

    let sys: FourCharCode = 1_937_339_168
    #expect(sys == "sys ".toFourCharCode(), "Failed for sys ")

    let unknown: FourCharCode = 0
    #expect(unknown == "".toFourCharCode(), "Failed for empty string")
  }

  @Test func roundtripAll() {
    let components = AudioUnitComponents.components(maybeFilter: nil)
    let componentCodes: Set<FourCharCode> = Set(
      components.map {
        [
          $0.audioComponentDescription.componentType,
          $0.audioComponentDescription.componentSubType,
          $0.audioComponentDescription.componentManufacturer,
        ]
      }.joined())

    #expect(!componentCodes.isEmpty)

    for fourCharCode in componentCodes {
      let s = fourCharCode.toString()
      let c = s.toFourCharCode()
      let s2 = c.toString()
      #expect(s == s2, "Failed for \(fourCharCode)")
    }
  }
}
