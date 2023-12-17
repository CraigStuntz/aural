import AVFoundation

struct UpdateConfig {
  let existingVersion: String
  let config: AudioUnitConfig

  func requestCurrentVersion() async -> Result<UpdateStatus, UpdateError> {
    guard let versionUrl = self.config.versionUrl, !versionUrl.isEmpty else {
      return .failure(
        .noConfiguration(
          description:
            "There is no update version URL for \(self.config.manufacturer) \(self.config.name)"))
    }
    guard let versionRegex = self.config.versionRegex, !versionRegex.isEmpty else {
      return .failure(
        .noConfiguration(
          description:
            "There is no update version Regex for \(self.config.manufacturer) \(self.config.name)"))
    }
    do {
      let currentVersion = try await HTTPVersionRetriever.retrieve(
        url: versionUrl, versionMatchRegex: versionRegex)
      if currentVersion != nil {
        let compatible = Versions.compatible(
          version1: currentVersion, version2: self.existingVersion)
        return .success(
          UpdateStatus(config: self, currentVersion: currentVersion, compatible: compatible))
      } else {
        return .failure(
          .configurationNotFoundInHttpResult(
            description: "Current version of \(self.config.name) not found"))
      }
    } catch {
      return .failure(
        .genericUpdateError(
          description:
            "Caught error \(error) while checking the current version of \(self.config.name)"))
    }
  }
}

struct UpdateConfigs {
  let noConfiguration: [String]
  let toUpdate: [UpdateConfig]

  init(configs: AudioUnitConfigs, components: [AVAudioUnitComponent]) {
    var noConfiguration: [String] = []
    var toUpdate: [UpdateConfig] = []
    let nonSystemComponents = components.filter({ !AudioUnitComponents.isSystemComponent($0) })
    for component in nonSystemComponents {
      let config = configs[component]
      if config != nil {
        toUpdate.append(
          UpdateConfig(
            existingVersion: component.versionString,
            config: config!
          ))
      } else {
        noConfiguration.append(
          "\(component.manufacturerName) \(component.name) (\(component.versionString))")
      }
    }
    self.noConfiguration = noConfiguration
    self.toUpdate = toUpdate
  }
}

enum UpdateError: Error, CustomStringConvertible {
  case configurationNotFoundInHttpResult(description: String)
  case noConfiguration(description: String)
  case webRequestFailed(description: String)
  case genericUpdateError(description: String)

  public var description: String {
    switch self {
    case .configurationNotFoundInHttpResult(let description): return description
    case .noConfiguration(let description): return description
    case .webRequestFailed(let description): return description
    case .genericUpdateError(let description): return description
    }
  }
}

struct UpdateStatus {
  let config: UpdateConfig
  let currentVersion: String?
  let compatible: Bool
}
