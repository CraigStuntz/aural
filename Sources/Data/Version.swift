import Foundation
import HTTPTypes
import HTTPTypesFoundation
import JMESPath

struct Version {
  static func compatible(version1: String?, version2: String?) -> Bool {
    guard let v1 = version1, let v2 = version2, !v1.isEmpty, !v2.isEmpty else {
      return false
    }
    if v1.count < v2.count {
      return v2.starts(with: v1)
    } else {
      return v2.starts(with: v2)
    }
  }

  static func httpGet(url: String, versionMatchRegex: String) async throws -> String? {
    let request = HTTPRequest(method: .get, url: URL(string: url)!)
    let (data, response) = try! await URLSession.shared.data(for: request)
    guard response.status == .ok else {
      print("Failed to download \(url), status \(response.status)")
      return nil
    }
    let body = String(decoding: data, as: UTF8.self)
    return try parseWithRegex(body, versionMatchRegex)
  }

  static func cleanUp(versionAsRead: String) -> String {
    return versionAsRead.replacingOccurrences(of: "_", with: ".")
  }

  static func parseWithJMESPath(_ body: String, _ versionMatchJmesPath: String) throws -> String? {
    let expression = try JMESExpression.compile(versionMatchJmesPath)
    let result = try expression.search(json: body, as: String.self)
    return result
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
