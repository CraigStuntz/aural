import Foundation

struct AudioUnitsConfig: Decodable {
  private enum CodingKeys: String, CodingKey {
    case manufacturer, name, typeName, versionUrl
  }

  let manufacturer: String
  let name: String
  let typeName: String
  let versionUrl: String?

  static let resourceFilename = "AudioUnits"
  static let resourceWithExtension = "plist"

  static func parseConfig() -> [AudioUnitsConfig] {
    if let url = Bundle.module.url(
      forResource: resourceFilename, withExtension: resourceWithExtension)
    {
      let data = try! Data(contentsOf: url)
      let decoder = PropertyListDecoder()
      let config = try! decoder.decode([AudioUnitsConfig].self, from: data)
      return config
    }
    fatalError("Cannot find \(resourceFilename).\(resourceWithExtension)")
  }
}
