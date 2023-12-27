import Foundation

extension String {
  func toFourCharCode() -> FourCharCode {
    guard self.utf8.count == 4 else {
      return 0
    }
    var code: FourCharCode = 0
    // Value has to consist of 4 printable ASCII characters, e.g. '420v'.
    // Note: This implementation does not enforce printable range (32-126)
    for byte in self.utf8 {
      code = code << 8 + FourCharCode(byte)
    }
    return code
  }
}
