import AVFoundation

struct UpdateAudioUnits {
  static func run(options: Options) async {
    let components = AudioUnitComponents.components(filter: options.filter)
    let audioUnitConfigs = AudioUnitConfigs()
    let updateConfigs = UpdateConfigs(audioUnitConfigs: audioUnitConfigs, components: components)
    if !updateConfigs.noConfiguration.isEmpty {
      let noConfigsData = updateConfigs.noConfiguration.map { [$0] }
      Table(headers: ["No update configurations found for:"], data: noConfigsData).printToConsole()
      print()
    }
    if updateConfigs.toUpdate.isEmpty {
      print("No Audio Units configured for update.")
    } else {
      print(".", terminator: "")
      var data: [[String]] = []
      var failures: [[String]] = []
      await withTaskGroup(of: Result<UpdateStatus, UpdateError>.self) { group in
        for updateConfig in updateConfigs.toUpdate {
          group.addTask { await updateConfig.requestCurrentVersion() }
        }
        for await result in group {
          print(".", terminator: "")
          switch result {
          case .success(let updateStatus):
            let currentVersion = updateStatus.currentVersion ?? "<unknown>"
            data.append([
              updateStatus.config.audioUnitConfig.manufacturer,
              updateStatus.config.audioUnitConfig.name,
              currentVersion,
              updateStatus.config.existingVersion,
              updateStatus.compatible ? "Y" : "N",
            ])
          case .failure(let updateError):
            failures.append([
              updateError.description
            ])
          }
        }
      }

      print()
      if !data.isEmpty {
        Table(
          headers: ["manufacturer", "name", "latest version", "local version", "up to date?"],
          data: data
        ).printToConsole()
      }
      if !failures.isEmpty {
        print("Errors encountered during update:")
        Table(headers: [], data: failures).printToConsole()
      }
    }
  }
}

struct UpdateConfig {
  let existingVersion: String
  let audioUnitConfig: AudioUnitConfig

  func requestCurrentVersion() async -> Result<UpdateStatus, UpdateError> {
    guard let versionUrl = self.audioUnitConfig.versionUrl, !versionUrl.isEmpty else {
      return .failure(
        .noConfiguration(
          description:
            "There is no update version URL for \(self.audioUnitConfig.manufacturer) \(self.audioUnitConfig.name)"
        ))
    }
    do {
      let currentVersion = try await Version.getAndParse(audioUnitConfig: self.audioUnitConfig)
      if currentVersion != nil {
        let compatible = Version.compatible(
          version1: currentVersion, version2: self.existingVersion)
        return .success(
          UpdateStatus(config: self, currentVersion: currentVersion, compatible: compatible))
      } else {
        return .failure(
          .configurationNotFoundInHttpResult(
            description: "Current version of \(self.audioUnitConfig.name) not found"))
      }
    } catch {
      return .failure(
        .genericUpdateError(
          description:
            "Caught error \(error) while checking the current version of \(self.audioUnitConfig.name)"
        ))
    }
  }
}

struct UpdateConfigs {
  let noConfiguration: [String]
  let toUpdate: [UpdateConfig]

  init(audioUnitConfigs: AudioUnitConfigs, components: [AVAudioUnitComponent]) {
    var noConfiguration: [String] = []
    var toUpdate: [UpdateConfig] = []
    let nonSystemComponents = components.filter({ !AudioUnitComponents.isSystemComponent($0) })
    for component in nonSystemComponents {
      let audioUnitConfig = audioUnitConfigs[component]
      if audioUnitConfig != nil {
        toUpdate.append(
          UpdateConfig(
            existingVersion: component.versionString,
            audioUnitConfig: audioUnitConfig!
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
