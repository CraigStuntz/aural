import Foundation

extension FourCharCode {
  func toString() -> String {
    guard self != 0 else {
      return ""
    }
    guard let c1 = UnicodeScalar((self >> 24) & 255),
      let c2 = UnicodeScalar((self >> 16) & 255),
      let c3 = UnicodeScalar((self >> 8) & 255),
      let c4 = UnicodeScalar(self & 255)
    else {
      return ""
    }

    var s: String = String(c1)
    s.append(Character(c2))
    s.append(Character(c3))
    s.append(Character(c4))
    return (s)
  }
}
