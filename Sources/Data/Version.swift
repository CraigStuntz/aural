import Foundation
import HTTPTypes
import HTTPTypesFoundation
import JMESPath

struct Version {
  static func compatible(version1: String, version2: String) -> Bool {
    guard version1.count < version2.count else {
      return version1.starts(with: version2)
    }
    return version2.starts(with: version1)
  }

  /// This is how Phase Plant stores their versions in their web site JSON file.
  static func fromInt(_ intVersion: Int) -> String {
    var result: [String] = []
    var remaining = intVersion
    for exp in [2, 1, 0] {
      // In any other PL, this would be
      // let modulus = 2**(8 * exp)
      // but Swift (5) has no exponentiation operator nor any means of doing an
      // exponentiation on an Int...
      let modulus = Int(pow(2, Double(8 * exp)))
      let remainder = remaining / modulus
      remaining -= (remainder * modulus)
      result.append(String(remainder))
    }
    return result.joined(separator: ".")
  }

  static func getAndParse(audioUnitConfig: AudioUnitConfig) async throws -> String? {
    guard let versionUrl = audioUnitConfig.versionUrl,
      let url = URL(string: versionUrl)
    else {
      fatalError(
        "audioUnitConfig.versionUrl must be non-nil and a valid URL before calling this function. Check it!"
      )
    }
    guard let body = try await httpGet(url: url) else {
      return nil
    }
    if let jmesPath = audioUnitConfig.versionJMESPathInt {
      guard let value: Int = try parseWithJMESPath(body, jmesPath) else {
        return nil
      }
      return fromInt(value)
    }
    if let regex = audioUnitConfig.versionRegex {
      return try parseWithRegex(body, regex)
    }
    return nil
  }

  static func httpGet(url: URL) async throws -> String? {
    let request = HTTPRequest(method: .get, url: url)
    let (data, response) = try await URLSession.shared.data(for: request)
    guard response.status == .ok else {
      print("Failed to download \(url), status \(response.status)")
      return nil
    }
    return String(decoding: data, as: UTF8.self)
  }

  static func cleanUp(versionAsRead: String) -> String {
    return versionAsRead.replacingOccurrences(of: "_", with: ".")
  }

  static func parseWithJMESPath<Value>(
    _ body: String, _ versionMatchJmesPath: String
  ) throws -> Value? {
    let expression = try JMESExpression.compile(versionMatchJmesPath)
    return try expression.search(json: body, as: Value.self)
  }

  static func parseWithRegex(_ body: String, _ versionMatchRegex: String) throws -> String? {
    let regex = try Regex(versionMatchRegex)
    if let match = body.firstMatch(of: regex) {
      if let captured = match.output[1].substring {
        return cleanUp(versionAsRead: String(captured))
      } else {
        print("No capture on document body given regex \(versionMatchRegex)")
      }
    }
    return nil
  }
}
