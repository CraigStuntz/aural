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
  static func parse(responseBody: String, audioUnitConfig: AudioUnitConfig) throws -> String? {
    if let jmesPath = audioUnitConfig.versionJMESPath {
      guard let value: String = try parseWithJMESPath(responseBody, jmesPath) else {
        Console.error(
          "Parsing response for Audio Unit \(audioUnitConfig.name) with JMESPath failed.")
        return nil
      }
      return value
    }
    if let jmesPath = audioUnitConfig.versionJMESPathInt {
      guard let value: Int = try parseWithJMESPath(responseBody, jmesPath) else {
        Console.error(
          "Parsing response for Audio Unit \(audioUnitConfig.name) with JMESPath failed.")
        return nil
      }
      return fromInt(value)
    }
    if let regex = audioUnitConfig.versionRegex {
      return try parseWithRegex(responseBody, regex)
    }
    Console.error(
      "No means of parsing response for Audio Unit \(audioUnitConfig.name) is configured")
    return nil
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
