import AVFoundation
import Foundation

struct AudioUnitConfig: Decodable {
  private enum CodingKeys: String, CodingKey {
    case manufacturer, name, system, typeName, versionJMESPathInt, versionRegex, versionUrl
  }

  let manufacturer: String
  let name: String
  let system: Bool?
  let typeName: String
  let versionJMESPathInt: String?
  let versionRegex: String?
  let versionUrl: String?

  static func toDictionaryKey(manufacturer: String, name: String, typeName: String) -> String {
    return "\(manufacturer)\t\(name)\t\(typeName)"
  }

  func toDictionaryKey() -> String {
    return AudioUnitConfig.toDictionaryKey(
      manufacturer: self.manufacturer, name: self.name, typeName: self.typeName)
  }
}

struct AudioUnitConfigs {
  static let resourceFilename = "AudioUnits"
  static let resourceWithExtension = "plist"

  static func parseConfig() -> [AudioUnitConfig] {
    if let url = Bundle.module.url(
      forResource: resourceFilename, withExtension: resourceWithExtension)
    {
      let data = try! Data(contentsOf: url)
      let decoder = PropertyListDecoder()
      let config = try! decoder.decode([AudioUnitConfig].self, from: data)
      return config
    }
    fatalError("Cannot find \(resourceFilename).\(resourceWithExtension)")
  }

  let dictionary: [String: AudioUnitConfig]

  init() {
    let configs = AudioUnitConfigs.parseConfig()
    let dictionary = Dictionary(uniqueKeysWithValues: configs.map { ($0.toDictionaryKey(), $0) })
    self.dictionary = dictionary
  }

  subscript(component: AVAudioUnitComponent) -> AudioUnitConfig? {
    return self.dictionary[
      AudioUnitConfig.toDictionaryKey(
        manufacturer: component.manufacturerName,
        name: component.name,
        typeName: component.typeName
      )]
  }
}
