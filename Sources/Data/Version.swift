import Foundation
import HTTPTypes
import HTTPTypesFoundation
import JMESPath

struct Version {
  /// Determines if `esistingVersion` is compatible with `latestVersion`
  ///
  /// A version is "compatible" with another version when it
  ///
  ///   * Has the same major version
  ///   * Has the sem minor version, or both minor versions are absent
  ///   * Has the same release version, or both release versions are absent
  ///   * Has the same build number, or one build number is absent
  static func compatible(latestVersion: String, existingVersion: String) -> Bool {
    let latestVersionParts =
      latestVersion.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
      .split(separator: ".")
    let existingVersionParts =
      existingVersion.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
      .split(separator: ".")
    guard
      latestVersionParts.count > 0
        && existingVersionParts.count > 0
        && (latestVersionParts.count == existingVersionParts.count
          || latestVersionParts.count >= 3 && existingVersionParts.count >= 3)
    else {
      return false
    }
    return zip(latestVersionParts, existingVersionParts).allSatisfy { (latestPart, existingPart) in
      latestPart == existingPart
    }
  }

  /// This is how Phase Plant stores their versions in their web site JSON file.
  static func fromInt(_ intVersion: Int) -> String {
    let digits = [2, 1, 0].map { byte in
      (intVersion >> (byte * 8)) & 0xFF
    }
    return digits.map { String($0) }.joined(separator: ".")
  }

  /// Asynchronously gets the latest version resource and parses the laterst version numver from that resource
  static func getAndParse(audioUnitConfig: AudioUnitConfig) async throws -> String? {
    guard let versionUrl = audioUnitConfig.versionUrl,
      let url = URL(string: versionUrl)
    else {
      fatalError(
        "audioUnitConfig.versionUrl \(audioUnitConfig.versionUrl as Optional) must be non-nil and a valid URL before calling this function. Check it!"
      )
    }
    guard let body = try await httpGet(url: url) else {
      Console.error("Fetching \(url) failed.")
      return nil
    }
    if let jmesPath = audioUnitConfig.versionJMESPath {
      guard let value: String = try parseWithJMESPath(body, jmesPath) else {
        Console.error("Parsing document \(url) with JMESPath failed.")
        return nil
      }
      return value
    }
    if let jmesPath = audioUnitConfig.versionJMESPathInt {
      guard let value: Int = try parseWithJMESPath(body, jmesPath) else {
        Console.error("Parsing document \(url) with JMESPath failed.")
        return nil
      }
      return fromInt(value)
    }
    if let regex = audioUnitConfig.versionRegex {
      return try parseWithRegex(body, regex)
    }
    Console.error("No means of parsing \(url) is configured")
    return nil
  }

  static func httpGet(url: URL) async throws -> String? {
    let request = HTTPRequest(method: .get, url: url)
    let (data, response) = try await URLSession.shared.data(for: request)
    guard response.status == .ok else {
      Console.warning("Failed to download \(url), status \(response.status)")
      return nil
    }
    return String(decoding: data, as: UTF8.self)
  }

  /// Resources represent version numvers differently. This function attempts to
  /// massage them into a standard `major.minor.release.build` format
  static func cleanUp(versionAsRead: String) -> String {
    let result = versionAsRead.replacingOccurrences(of: "_", with: ".")
    if result.contains(".") {
      return result
    }
    // U-he Diva returns the version number without dots; 147 == 1.4.7
    return interleaveDots(versionAsRead: result)
  }

  static func interleaveDots(versionAsRead: String) -> String {
    guard versionAsRead.count > 2 else {
      return versionAsRead
    }
    let chars = Array(versionAsRead).compactMap { String($0) }
    let dots = Array.init(repeating: ".", count: chars.count)
    let zipped = zip(chars, dots).flatMap({ [$0, $1] })
    return zipped.prefix(chars.count + dots.count - 1).joined()
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
        Console.error("No capture on document body given regex \(versionMatchRegex)")
      }
    }
    throw UpdateError.noRegexMatch(regex: versionMatchRegex)
  }
}
