import Foundation
import HTTPTypes
import HTTPTypesFoundation

struct Http {
  static func get(url: URL) async throws -> String {
    let request = HTTPRequest(method: .get, url: url)
    let (data, response) = try await URLSession.shared.data(for: request)
    guard response.status == .ok else {
      Console.warning("Failed to download \(url), status \(response.status)")
      return ""
    }
    return String(decoding: data, as: UTF8.self)
  }
}
