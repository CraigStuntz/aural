import AVFoundation
import Foundation

struct AudioUnitConfig: Codable {
  private enum CodingKeys: String, CodingKey {
    case manufacturer, name, system, typeName, update, versionJMESPath, versionJMESPathInt,
      versionRegex, versionUrl
  }

  let manufacturer: String
  let name: String
  let system: Bool?
  let typeName: String
  let update: String?
  let versionJMESPath: String?
  let versionJMESPathInt: String?
  let versionRegex: String?
  let versionUrl: String?

  static func fromComponent(component: AVAudioUnitComponent) -> AudioUnitConfig {
    let manufacturer = component.audioComponentDescription.componentManufacturer.toString()
    let system: Bool? = manufacturer == "aapl" || manufacturer == "sys " ? true : nil
    return AudioUnitConfig(
      manufacturer: manufacturer,
      name: component.audioComponentDescription.componentSubType.toString(),
      system: system,
      typeName: component.audioComponentDescription.componentType.toString(),
      update: nil,
      versionJMESPath: nil,
      versionJMESPathInt: nil,
      versionRegex: nil,
      versionUrl: nil
    )
  }

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
      do {
        let data = try Data(contentsOf: url)
        let decoder = PropertyListDecoder()
        let config = try decoder.decode([AudioUnitConfig].self, from: data)
        return config
      } catch {
        fatalError("Could not read AudioUnits.plist due to \(error)")
      }
    }
    fatalError("Cannot find \(resourceFilename).\(resourceWithExtension)")
  }

  func toConfig(_ component: AVAudioUnitComponent) -> AudioUnitConfig {
    if let config = self[ComponentMetadata(avAudioUnitComponent: component)] {
      return config
    }
    return AudioUnitConfig.fromComponent(component: component)
  }

  func noMatch(config: AudioUnitConfig, components: [AVAudioUnitComponent]) -> Bool {
    let contains: Bool = components.contains { component in
      component.audioComponentDescription.componentManufacturer.toString() == config.manufacturer
        && component.audioComponentDescription.componentSubType.toString() == config.name
        && component.audioComponentDescription.componentType.toString() == config.typeName
    }
    return !contains
  }

  func compareConfig(_ a: AudioUnitConfig, _ b: AudioUnitConfig) -> Bool {
    if a.manufacturer != b.manufacturer { return a.manufacturer < b.manufacturer }
    if a.name != b.name { return a.name < b.name }
    return a.typeName < b.typeName
  }

  func toConfigs(_ components: [AVAudioUnitComponent]) -> [AudioUnitConfig] {
    var componentConfigs = components.map { component in toConfig(component) }
    let noMatchingComponentConfigs: [AudioUnitConfig] = self.configs.filter { config in
      noMatch(config: config, components: components)
    }
    componentConfigs.append(contentsOf: noMatchingComponentConfigs)
    componentConfigs.sort { a, b in compareConfig(a, b) }
    return componentConfigs
  }

  func toPlist(_ components: [AVAudioUnitComponent]) throws -> Data {
    let configs = toConfigs(components)
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .xml
    return try encoder.encode(configs)
  }

  func writeConfig(_ components: [AVAudioUnitComponent], _ filename: String) {
    let docsBaseURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let plistURL = URL(fileURLWithPath: filename, relativeTo: docsBaseURL)
    do {
      let data = try toPlist(components)
      do {
        try data.write(to: plistURL, options: .atomic)
      } catch (let err) {
        Console.error("Error writing file", err.localizedDescription)
      }
    } catch (let err) {
      Console.error("Error encoding as plist", err.localizedDescription)
    }
  }

  let configs: [AudioUnitConfig]
  let dictionary: [String: AudioUnitConfig]

  init() {
    self.configs = AudioUnitConfigs.parseConfig()
    self.dictionary = Dictionary(uniqueKeysWithValues: configs.map { ($0.toDictionaryKey(), $0) })
  }

  subscript(component: AVAudioUnitComponent) -> AudioUnitConfig? {
    return self.dictionary[
      AudioUnitConfig.toDictionaryKey(
        manufacturer: component.audioComponentDescription.componentManufacturer.toString(),
        name: component.audioComponentDescription.componentSubType.toString(),
        typeName: component.audioComponentDescription.componentType.toString()
      )
    ]
  }

  subscript(metadata: ComponentMetadata) -> AudioUnitConfig? {
    return self.dictionary[
      AudioUnitConfig.toDictionaryKey(
        manufacturer: metadata.manufacturerName,
        name: metadata.name,
        typeName: metadata.typeName
      )]
  }
}
