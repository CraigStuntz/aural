import Foundation
import HTTPTypes
import HTTPTypesFoundation

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
    print("Loading \(url)...")
    let (data, response) = try! await URLSession.shared.data(for: request)
    guard response.status == .ok else {
      print("Failed to download \(url), status \(response.status)")
      return nil
    }
    let body = String(decoding: data, as: UTF8.self)
    print("Finished!")
    let regex = try Regex(versionMatchRegex)
    if let match = body.firstMatch(of: regex) {
      if let captured = match.output[1].substring {
        return cleanUp(versionAsRead: String(captured))
      } else {
        print("No capture on document body given regex \(versionMatchRegex)")
      }
    } else {
      print("No match on document body given regex \(versionMatchRegex)")
    }
    return nil
  }

  static func cleanUp(versionAsRead: String) -> String {
    return versionAsRead.replacingOccurrences(of: "_", with: ".")
  }
}
