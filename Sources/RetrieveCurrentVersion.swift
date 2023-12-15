import Foundation
import HTTPTypes
import HTTPTypesFoundation

struct HTTPVersionRetriever {
  static func retrieve(url: String, versionMatchRegex: String) async throws -> String? {
    let request = HTTPRequest(method: .get, url: URL(string: url)!)
    let (data, response) = try! await URLSession.shared.data(for: request)
    guard response.status == .ok else {
      print("Failed to download \(url), status \(response.status)")
      return nil
    }
    let body = String(decoding: data, as: UTF8.self)
    print ("Finished loading...")
    let regex = try Regex(versionMatchRegex) 
    if let match = body.firstMatch(of: regex) {
      if let captured = match.output[1].substring {
        return cleanupVersion(versionAsRead: String(captured))
      } else {
        print ("No capture on document body given regex \(versionMatchRegex)")
      }
    } else {
      print ("No match on document body given regex \(versionMatchRegex)")
    }
    return nil
  }

  static func cleanupVersion(versionAsRead: String) -> String {
    return versionAsRead.replacingOccurrences(of: "_", with: ".")
  }
}
