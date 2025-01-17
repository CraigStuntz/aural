import Foundation
import HTTPTypes
import HTTPTypesFoundation

struct Http {
  static func get(url: URL) async throws -> Result<String, HttpError> {
    let request = HTTPRequest(method: .get, url: url)
    let (data, response) = try await URLSession.shared.data(for: request)
    guard response.status == .ok else {
      return .failure(.status(responseStatus: response.status, url: url))
    }
    return .success(String(decoding: data, as: UTF8.self))
  }
}

enum HttpError: Error, CustomStringConvertible {
  case status(responseStatus: HTTPResponse.Status, url: URL)

  public var description: String {
    switch self {
    case .status(let status, let url): return "Failed to download \(url), status \(status)"
    }
  }
}
